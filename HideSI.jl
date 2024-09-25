include("./Dataset.jl")
include("./HUIM/Utility.jl")
include("./HUIM/Algorithm/D2HUP.jl")
#include("./HUIM/Algorithm/HUI_Miner.jl")

#include("./PPUM/Algorithm/Evolutionary/PSO2DI.jl")
include("./PPUM/Algorithm/Evolutionary/PPUMGAT.jl")
include("./PPUM/Algorithm/Evolutionary/PSO2DI_v1.jl")
include("./PPUM/SideEffects.jl")

include("./Performance.jl")

using StatsBase

function hide_SI(dataset::Dataset, mut::Float64, sip::Float64, algs::Vector{Function})
    @assert mut >= dataset.mut[] "Invalid minimum utility threshold"
    min_util = ceil(Int, (dataset.total_util[] * mut) / 100)
    HUIs = Dict(itemset => util for (itemset, util) in pairs(dataset.huis[]) if util >= min_util)

    n_S = round(Int, (length(HUIs) * sip) / 100)
    S = Set(sample(collect(keys(HUIs)), n_S, replace=false))
    
    M = 10
    max_iterations = 50
    w1 = 0.8
    w2 = 0.2

    algs_metrics = Dict{String, Metrics}(repr(alg) => Metrics() for alg in algs)

    for alg in algs
        println("\nBegin: $(repr(alg))")
        runtime = @elapsed sanitized_transactions = alg(dataset.transactions, dataset.utilTable, S, HUIs, min_util, M, max_iterations, w1, w2)
    
        sanitized_HUIs = Dict{Set{String}, Int}()
        for itemset in keys(HUIs)
            util = utility(itemset, sanitized_transactions, dataset.utilTable)
            if util >= min_util
                sanitized_HUIs[itemset] = util
            end
        end
    
        se = SideEffects(S, HUIs, sanitized_HUIs)
        println("\t", "Runtime = ", runtime, " (seconds)")
        println("\t", se)
        println("End: $(repr(alg))")

        algs_metrics[repr(alg)]["runtime"] = runtime
        algs_metrics[repr(alg)]["HF"] = se.HF
        algs_metrics[repr(alg)]["MC"] = se.MC
    end

    return algs_metrics
end

algorithms = [ppumgat, PSO2DI_v1]
dataset_names = ["chess", "foodmart", "mushrooms", "t25i10d10k"]

dataset = load_dataset(dataset_names[4])
println(dataset)
perf = load_performance(dataset.name)

#=
muts = [0.05, 0.06, 0.07, 0.08, 0.09]
sip = 1.5

for mut in muts
    println(mut)
    algs_metrics = hide_SI(dataset, mut, sip, algorithms)
    add!(perf, mut, sip, algs_metrics)
end
=#


mut = 0.3
sips = [0.6, 0.7, 0.8, 0.9, 1.0]

for sip in sips
    println(sip)
    algs_metrics = hide_SI(dataset, mut, sip, algorithms)
    add!(perf, mut, sip, algs_metrics)
end

save(perf)