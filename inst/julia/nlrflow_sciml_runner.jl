#!/usr/bin/env julia
# nlrFlow optional SciML backend. This file is invoked by R; it does not install packages.

using CSV, DataFrames, JSON3, Statistics, LinearAlgebra, Random, StableRNGs, Serialization
using Lux, ComponentArrays, OrdinaryDiffEq, SciMLSensitivity
using Optimization, OptimizationOptimisers, OptimizationOptimJL
using Zygote, Optim

jget(x, k::AbstractString, default=nothing) = haskey(x, Symbol(k)) ? x[Symbol(k)] : (haskey(x, k) ? x[k] : default)
strvec(x) = x === nothing ? String[] : String.(collect(x))
floatvec(x) = x === nothing ? Float64[] : Float64.(collect(x))
intvec(x) = x === nothing ? Int[] : Int.(collect(x))

function activation(name)
    name == "relu" && return Lux.relu
    name == "swish" && return x -> x / (1 + exp(-x))
    tanh
end

function make_model(nin, hidden, nout, actname="tanh")
    act = activation(actname)
    layers = Any[]
    prev = nin
    for h in hidden
        push!(layers, Lux.Dense(prev, h, act)); prev = h
    end
    push!(layers, Lux.Dense(prev, nout))
    Lux.Chain(layers...)
end

function interp1(tgrid, values, t)
    t <= tgrid[1] && return values[1]
    t >= tgrid[end] && return values[end]
    j = searchsortedlast(tgrid, t)
    j >= length(tgrid) && return values[end]
    a = (t - tgrid[j]) / (tgrid[j+1] - tgrid[j])
    (1-a)*values[j] + a*values[j+1]
end

function prepare_timeseries(df, cfg)
    tname = String(jget(cfg,"time")); states = strvec(jget(cfg,"states")); covs = strvec(jget(cfg,"covariates", String[]))
    sort!(df, Symbol(tname)); times = Float64.(df[!, Symbol(tname)])
    length(unique(times)) == length(times) || error("Neural ODE/UDE runner expects one row per time for a single trajectory.")
    Y = permutedims(Matrix{Float64}(df[:, Symbol.(states)]))
    C = isempty(covs) ? zeros(0,length(times)) : permutedims(Matrix{Float64}(df[:, Symbol.(covs)]))
    times, states, covs, Y, C
end

function covdict(covs, times, C, t; override_name=nothing, override_times=Float64[], override_values=Float64[])
    d = Dict{String,Float64}()
    for (i,nm) in enumerate(covs)
        if override_name !== nothing && nm == override_name
            j = searchsortedlast(override_times, t); j = clamp(j, 1, length(override_values))
            d[nm] = override_values[j]
        else
            d[nm] = interp1(times, view(C,i,:), t)
        end
    end
    d
end

function nn_input(u, cov, covs, t)
    # Keep the state element type generic so AD/sensitivity methods can propagate through the RHS.
    vcat(collect(u), [cov[nm] for nm in covs], [t])
end

function save_dynamic_outputs(outdir, times, states, Y, pred; training=nothing, decomposition=nothing, diagnostics=nothing, parameters=nothing)
    d = DataFrame(time = times)
    for (i,st) in enumerate(states)
        d[!, Symbol(st*"_observed")] = vec(Y[i,:])
        d[!, Symbol(st*"_predicted")] = vec(pred[i,:])
    end
    CSV.write(joinpath(outdir,"predictions.csv"), d)
    training !== nothing && CSV.write(joinpath(outdir,"training.csv"), training)
    decomposition !== nothing && CSV.write(joinpath(outdir,"decomposition.csv"), decomposition)
    diagnostics !== nothing && CSV.write(joinpath(outdir,"diagnostics.csv"), diagnostics)
    parameters !== nothing && CSV.write(joinpath(outdir,"parameters.csv"), parameters)
    rmse = sqrt(mean(abs2, vec(Y .- pred)))
    CSV.write(joinpath(outdir,"summary.csv"), DataFrame(metric=["RMSE","n_time","n_state"], value=[rmse,length(times),length(states)]))
end

function train_neural_ode(df, cfg, outdir; ude=false)
    times, states, covs, Y, C = prepare_timeseries(df,cfg)
    hidden = intvec(jget(cfg,"hidden",[16,16])); seed = Int(jget(cfg,"seed",20260817)); maxiters = Int(jget(cfg,"maxiters",500))
    lr = Float64(jget(cfg,"learning_rate",0.01)); refine = Bool(jget(cfg,"refine",true)); act = String(jget(cfg,"activation","tanh"))
    scale = Float64(jget(cfg,"neural_scale",1.0)); weight_decay = Float64(jget(cfg,"weight_decay",0.0))
    rng = StableRNG(seed); model = make_model(length(states)+length(covs)+1,hidden,length(states),act); ps,st = Lux.setup(rng,model); p0=ComponentArray(ps)
    known_rhs = String[]; kp = Dict{String,Float64}()
    if ude
        known_rhs = strvec(jget(cfg,"known_rhs"))
        kpobj = jget(cfg,"known_parameters", Dict())
        for (k,v) in pairs(kpobj); kp[String(k)] = Float64(v); end
        src = "function nlr_known_rhs(u,cov,kp,t)\nreturn [" * join(known_rhs, ",") * "]\nend"
        Core.eval(Main, Meta.parse(src))
    end
    function rhs!(du,u,p,t)
        cv = covdict(covs,times,C,t); inp=nn_input(u,cv,covs,t); nn,_=model(inp,p,st)
        if ude
            du .= nlr_known_rhs(u,cv,kp,t) .+ scale .* nn
        else
            du .= nn
        end
        nothing
    end
    u0 = vec(Y[:,1]); prob = ODEProblem(rhs!,u0,(times[1],times[end]),p0)
    function predict(p)
        Array(solve(remake(prob;p=p),Tsit5();saveat=times,abstol=1e-7,reltol=1e-6,
                    sensealg=InterpolatingAdjoint(autojacvec=ZygoteVJP())))
    end
    loss(p) = mean(abs2, Y .- predict(p)) + weight_decay*sum(abs2, p)
    hist_iter=Int[]; hist_loss=Float64[]; iter=Ref(0)
    callback = function (state,l)
        iter[] += 1; push!(hist_iter,iter[]); push!(hist_loss,Float64(l)); false
    end
    optf=OptimizationFunction((x,p)->loss(x),Optimization.AutoZygote()); optprob=OptimizationProblem(optf,p0)
    sol1=Optimization.solve(optprob,OptimizationOptimisers.Adam(lr);callback=callback,maxiters=maxiters)
    pfit=sol1.u
    if refine
        optprob2=remake(optprob;u0=pfit)
        sol2=Optimization.solve(optprob2,OptimizationOptimJL.BFGS();callback=callback,maxiters=max(50,Int(round(maxiters/3))))
        pfit=sol2.u
    end
    pred=predict(pfit); training=DataFrame(iteration=hist_iter,loss=hist_loss)
    decomp=nothing
    if ude
        rows=NamedTuple[]
        for j in eachindex(times)
            u=vec(pred[:,j]); cv=covdict(covs,times,C,times[j]); nn,_=model(nn_input(u,cv,covs,times[j]),pfit,st); kn=nlr_known_rhs(u,cv,kp,times[j])
            for i in eachindex(states)
                base=(time=times[j],state=states[i],observed=Y[i,j],fitted=u[i],known=kn[i],neural=scale*nn[i],total=kn[i]+scale*nn[i])
                extra=NamedTuple{Tuple(Symbol.(covs))}(Tuple(cv[nm] for nm in covs))
                push!(rows,merge(base,extra))
            end
        end
        decomp=DataFrame(rows)
    end
    diagnostics=DataFrame(metric=["final_training_loss","physics_loss"],value=[isempty(hist_loss) ? NaN : hist_loss[end],NaN])
    save_dynamic_outputs(outdir,times,states,Y,pred;training=training,decomposition=decomp,diagnostics=diagnostics)
    bundle=Dict("mode"=>ude ? "ude" : "neural_ode","model"=>model,"p"=>pfit,"st"=>st,"times"=>times,"states"=>states,"covariates"=>covs,"Y"=>Y,"C"=>C,"u0"=>u0,"config"=>Dict(String(k)=>v for (k,v) in pairs(cfg)),"known_rhs"=>known_rhs,"known_parameters"=>kp,"neural_scale"=>scale)
    serialize(joinpath(outdir,"model.jls"),bundle)
end

function richards_runner(df,cfg,outdir)
    using NeuralPDE, Optim, LineSearches
    tname=String(jget(cfg,"time")); yname=String(jget(cfg,"response")); zname=String(jget(cfg,"depth")); parsobj=jget(cfg,"parameters")
    pars=Dict{String,Float64}();for (k,v) in pairs(parsobj);pars[String(k)]=Float64(v);end
    times=sort(unique(Float64.(df[!,Symbol(tname)]))); depths=sort(unique(Float64.(df[!,Symbol(zname)])))
    Y=fill(NaN,length(depths),length(times))
    for r in eachrow(df)
        i=findfirst(==(Float64(r[Symbol(zname)])),depths);j=findfirst(==(Float64(r[Symbol(tname)])),times);Y[i,j]=Float64(r[Symbol(yname)])
    end
    any(x -> !isfinite(x), Y) && error("Richards PINN currently requires a complete depth × time observation grid.")
    covs=strvec(jget(cfg,"covariates",String[])); C=zeros(length(covs),length(times))
    for (ci,nm) in enumerate(covs), (j,t) in enumerate(times)
        vals=Float64.(df[df[!,Symbol(tname)].==t,Symbol(nm)]);C[ci,j]=mean(vals)
    end
    rainname=findfirst(x->occursin("rain",lowercase(x))||occursin("irrig",lowercase(x)),covs)
    etname=findfirst(x->occursin("et",lowercase(x)),covs)
    function rain_at(t); rainname===nothing ? 0.0 : interp1(times,view(C,rainname,:),t)/10.0; end # mm/d -> cm/d
    function et_at(t); etname===nothing ? 0.0 : interp1(times,view(C,etname,:),t)/10.0; end
    p0=[pars["theta_r"],pars["theta_s"],pars["alpha"],pars["n"],pars["Ks"]]
    function richards(u,p,t)
        theta_r,theta_s,alpha,n,Ks = p; n=abs(n)+1.0001;alpha=abs(alpha)+1e-7;Ks=abs(Ks)+1e-7;m=1-1/n
        th=clamp.(u,theta_r+1e-7,theta_s-1e-7);Se=clamp.((th.-theta_r)./(theta_s-theta_r),1e-6,1-1e-6)
        h=-((Se.^(-1/m).-1).^(1/n))./alpha
        K=Ks.*sqrt.(Se).*(1 .- (1 .- Se.^(1/m)).^m).^2
        q=zeros(length(depths)+1);q[1]=rain_at(t)
        for i in 1:(length(depths)-1)
            dz=depths[i+1]-depths[i];q[i+1]=0.5*(K[i]+K[i+1])*(1-(h[i+1]-h[i])/dz)
        end
        q[end]=K[end]
        du=zeros(length(depths))
        for i in eachindex(depths)
            dz = i==1 ? (length(depths)>1 ? depths[2]-depths[1] : 10.0) : depths[i]-depths[i-1]
            sink = i==1 ? et_at(t)/max(dz,1.0) : 0.0
            du[i]=(q[i]-q[i+1])/max(dz,1e-6)-sink
        end
        du
    end
    prob=ODEProblem(richards,vec(Y[:,1]),(times[1],times[end]),p0)
    hidden=intvec(jget(cfg,"hidden",[24,24]));rng=StableRNG(Int(jget(cfg,"seed",20260817)))
    chain=make_model(1,hidden,length(depths),"tanh"); ps,_=Lux.setup(rng,chain); opt=Optim.LBFGS(linesearch=LineSearches.BackTracking())
    W=fill(1/length(times),length(times));dataset=vcat([vec(Y[i,:]) for i in 1:size(Y,1)],[times,W])
    dt=length(times)>1 ? minimum(diff(times))/2 : 0.1
    estimate=Bool(jget(cfg,"estimate_parameters",false))
    strategy_name = String(jget(cfg,"strategy","weighted_interval"))
    ncoll = Int(jget(cfg,"collocation_points",500))
    strategy = strategy_name == "grid" ? NeuralPDE.GridTraining(dt) : NeuralPDE.WeightedIntervalTraining(fill(1/3,3),ncoll)
    alg=NeuralPDE.NNODE(chain,opt,ps;strategy=strategy,dataset=dataset,param_estim=estimate)
    sol=solve(prob,alg;verbose=false,abstol=1e-6,maxiters=Int(jget(cfg,"maxiters",1500)),saveat=times)
    pred=Array(sol)
    states=["theta_depth_"*replace(string(z),"."=>"_") for z in depths]
    pfit = p0
    if estimate
        try
            pfit = Float64.(collect(sol.k.u.p))
        catch
            @warn "NeuralPDE parameter estimates could not be extracted; reporting starting physical parameters."
        end
    end
    # A numerical physics-residual diagnostic evaluated on the learned trajectory.
    phys = Float64[]
    if length(times) > 2
        for j in 2:(length(times)-1)
            dudt_num=(pred[:,j+1].-pred[:,j-1])./(times[j+1]-times[j-1])
            append!(phys, dudt_num .- richards(pred[:,j],pfit,times[j]))
        end
    end
    physics_loss = isempty(phys) ? NaN : mean(abs2,phys)
    save_dynamic_outputs(outdir,times,states,Y,pred;diagnostics=DataFrame(metric=["physics_loss"],value=[physics_loss]))
    long=DataFrame(time=Float64[],depth=Float64[],observed=Float64[],predicted=Float64[])
    for j in eachindex(times),i in eachindex(depths);push!(long,(times[j],depths[i],Y[i,j],pred[i,j]));end
    CSV.write(joinpath(outdir,"predictions.csv"),long)
    CSV.write(joinpath(outdir,"parameters.csv"),DataFrame(parameter=["theta_r","theta_s","alpha","n","Ks"],value=pfit))
end

function pinn_runner(df,cfg,outdir)
    problem=String(jget(cfg,"problem"))
    problem=="richards_1d" && return richards_runner(df,cfg,outdir)
    using NeuralPDE, Optim, LineSearches
    tname=String(jget(cfg,"time")); yname=String(jget(cfg,"response"));sort!(df,Symbol(tname));times=Float64.(df[!,Symbol(tname)]);y=Float64.(df[!,Symbol(yname)])
    pobj=jget(cfg,"parameters");pars=Dict{String,Float64}();for (k,v) in pairs(pobj);pars[String(k)]=Float64(v);end
    if problem=="logistic_growth"
        p0=[pars["r"],pars["K"]]; f=(u,p,t)->[p[1]*u[1]*(1-u[1]/abs(p[2]))]
    elseif problem=="first_order_nutrient"
        p0=[pars["k"],pars["K"]]; f=(u,p,t)->[abs(p[1])*(abs(p[2])-u[1])]
    else
        error("Unsupported PINN problem template: $problem")
    end
    prob=ODEProblem(f,[y[1]],(times[1],times[end]),p0);hidden=intvec(jget(cfg,"hidden",[24,24]));chain=make_model(1,hidden,1,"tanh")
    rng=StableRNG(Int(jget(cfg,"seed",20260817))); ps,_=Lux.setup(rng,chain)
    opt=Optim.LBFGS(linesearch=LineSearches.BackTracking());W=fill(1/length(times),length(times));dataset=[y,times,W]
    dt=length(times)>1 ? minimum(diff(times))/2 : 0.1; estimate=Bool(jget(cfg,"estimate_parameters",false))
    strategy_name = String(jget(cfg,"strategy","weighted_interval"))
    ncoll = Int(jget(cfg,"collocation_points",500))
    strategy = strategy_name == "grid" ? NeuralPDE.GridTraining(dt) : NeuralPDE.WeightedIntervalTraining(fill(1/3,3),ncoll)
    alg=NeuralPDE.NNODE(chain,opt,ps;strategy=strategy,dataset=dataset,param_estim=estimate)
    sol=solve(prob,alg;verbose=false,abstol=1e-6,maxiters=Int(jget(cfg,"maxiters",1500)),saveat=times);pred=reshape(Array(sol),1,:)
    pfit=p0
    if estimate
        try pfit=Float64.(collect(sol.k.u.p)) catch; @warn "NeuralPDE parameter estimates could not be extracted; reporting starting physical parameters." end
    end
    phys=Float64[]
    if length(times)>2
        for j in 2:(length(times)-1)
            du_num=(pred[1,j+1]-pred[1,j-1])/(times[j+1]-times[j-1]);push!(phys,du_num-f([pred[1,j]],pfit,times[j])[1])
        end
    end
    physics_loss=isempty(phys) ? NaN : mean(abs2,phys)
    pnames = problem=="logistic_growth" ? ["r","K"] : ["k","K"]
    save_dynamic_outputs(outdir,times,[yname],reshape(y,1,:),pred;parameters=DataFrame(parameter=pnames,value=pfit),diagnostics=DataFrame(metric=["physics_loss"],value=[physics_loss]))
end

function opfun(name)
    name=="+" && return +; name=="-" && return -; name=="*" && return *; name=="/" && return /
    error("Unsupported binary operator: $name")
end
function uopfun(name)
    name=="exp" && return exp; name=="log" && return x->log(abs(x)+1e-8); name=="sqrt" && return x->sqrt(abs(x)); name=="sin" && return sin; name=="cos" && return cos
    error("Unsupported unary operator: $name")
end

function symbolic_runner(df,cfg,outdir)
    using SymbolicRegression
    # The search is stochastic. Seed Julia's global RNG so the user-requested seed is
    # honored. Multithreaded evolutionary search can still show small platform-level
    # differences, so nlrFlow treats candidates as hypotheses that must be refitted.
    Random.seed!(Int(jget(cfg,"seed",20260817)))
    response=String(jget(cfg,"response"));preds=strvec(jget(cfg,"predictors"));X=permutedims(Matrix{Float64}(df[:,Symbol.(preds)]));y=Float64.(df[!,Symbol(response)])
    bin=[opfun(x) for x in strvec(jget(cfg,"binary_operators",["+","-","*","/"]))];un=[uopfun(x) for x in strvec(jget(cfg,"unary_operators",["exp","log","sqrt"]))]
    parmode=Symbol(String(jget(cfg,"parallelism","serial")));deterministic=Bool(jget(cfg,"deterministic",true))
    deterministic && parmode != :serial && error("deterministic symbolic search requires parallelism=:serial")
    options=SymbolicRegression.Options(binary_operators=bin,unary_operators=un,maxsize=Int(jget(cfg,"maxsize",18)),parsimony=1e-4,deterministic=deterministic)
    hof=SymbolicRegression.equation_search(X,y;niterations=Int(jget(cfg,"niterations",200)),options=options,variable_names=preds,parallelism=parmode,verbosity=0,progress=false)
    dom=SymbolicRegression.calculate_pareto_frontier(hof);rows=NamedTuple[]
    for member in dom
        c=SymbolicRegression.compute_complexity(member,options);loss=member.loss;eq=SymbolicRegression.string_tree(member.tree,options;variable_names=preds)
        push!(rows,(complexity=c,loss=loss,equation=eq))
    end
    CSV.write(joinpath(outdir,"candidates.csv"),DataFrame(rows));CSV.write(joinpath(outdir,"summary.csv"),DataFrame(metric=["n_candidates"],value=[length(rows)]))
end

function control_runner(cfg,outdir)
    src=String(jget(cfg,"source_dir"));modelpath=joinpath(src,"model.jls");isfile(modelpath)||error("Saved SciML model was not found: $modelpath")
    b=deserialize(modelpath);mode=String(b["mode"]);model=b["model"];pfit=b["p"];st=b["st"];times=Float64.(b["times"]);states=String.(b["states"]);covs=String.(b["covariates"]);C=b["C"];u0=Float64.(b["u0"])
    control_name=String(jget(cfg,"control_covariate"));control_name in covs || error("control_covariate must be one of the covariates used during model training.")
    ctimes=floatvec(jget(cfg,"control_times"));lo=floatvec(jget(cfg,"lower"));up=floatvec(jget(cfg,"upper"));initial=floatvec(jget(cfg,"initial"));target=String(jget(cfg,"target_state"));idx=findfirst(==(target),states);idx===nothing&&error("target_state was not fitted.")
    penalty=Float64(jget(cfg,"input_penalty",0.01));scale=Float64(get(b,"neural_scale",1.0));kp=get(b,"known_parameters",Dict{String,Float64}());rhs=get(b,"known_rhs",String[])
    if mode=="ude"
        srcfun="function nlr_control_known(u,cov,kp,t)\nreturn ["*join(rhs,",")*"]\nend";Core.eval(Main,Meta.parse(srcfun))
    end
    function simulate(ctrl)
        function f!(du,u,p,t)
            cv=covdict(covs,times,C,t;override_name=control_name,override_times=ctimes,override_values=ctrl);nn,_=model(nn_input(u,cv,covs,t),pfit,st)
            if mode=="ude";du .= nlr_control_known(u,cv,kp,t) .+ scale.*nn;else;du .= nn;end;nothing
        end
        prob=ODEProblem(f!,u0,(times[1],times[end]));Array(solve(prob,Tsit5();saveat=times,abstol=1e-7,reltol=1e-6))
    end
    # Penalize the time-integrated control, not just the vector sum. A control at the terminal
    # instant has zero duration and therefore no artificial cost or benefit.
    durations = length(ctimes) > 1 ? vcat(diff(ctimes), max(times[end]-ctimes[end],0.0)) : [max(times[end]-times[1],0.0)]
    objective(x,p)=begin pr=simulate(x); -pr[idx,end]+penalty*dot(x,durations) end
    optf=OptimizationFunction(objective);prob=OptimizationProblem(optf,initial,lb=lo,ub=up)
    sol=Optimization.solve(prob,Optim.NelderMead();maxiters=Int(jget(cfg,"maxiters",300)));best=Float64.(sol.u);pred=simulate(best)
    CSV.write(joinpath(outdir,"control.csv"),DataFrame(time=ctimes,control=best,duration=durations,integrated_input=best.*durations));pd=DataFrame(time=times);for (i,stn) in enumerate(states);pd[!,Symbol(stn*"_predicted")]=vec(pred[i,:]);end;CSV.write(joinpath(outdir,"predictions.csv"),pd)
    CSV.write(joinpath(outdir,"summary.csv"),DataFrame(metric=["objective","terminal_target","integrated_control"],value=[objective(best,nothing),pred[idx,end],dot(best,durations)]))
end

function main()
    length(ARGS)>=4 || error("Usage: nlrflow_sciml_runner.jl MODE CONFIG_JSON INPUT_CSV|NONE OUTPUT_DIR")
    mode,config_path,input_path,outdir=ARGS[1],ARGS[2],ARGS[3],ARGS[4];mkpath(outdir);cfg=JSON3.read(read(config_path,String));df=input_path=="NONE" ? DataFrame() : CSV.read(input_path,DataFrame)
    if mode=="neural_ode";train_neural_ode(df,cfg,outdir;ude=false)
    elseif mode=="ude";train_neural_ode(df,cfg,outdir;ude=true)
    elseif mode=="pinn";pinn_runner(df,cfg,outdir)
    elseif mode=="symbolic";symbolic_runner(df,cfg,outdir)
    elseif mode=="control";control_runner(cfg,outdir)
    else;error("Unsupported nlrFlow SciML mode: $mode")
    end
end

main()
