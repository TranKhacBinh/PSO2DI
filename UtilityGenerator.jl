include("./Dataset.jl")
using StatsBase

function gen_ext_util(items::Set{String}, ext_util_range::UnitRange{Int})::Dict{String, Int}
    mu = mean(log.(ext_util_range))
    sigma = std(log.(ext_util_range))
    pdf = (exp.(- (log.(ext_util_range) .- mu ).^2 ./(2 * sigma^2)) ./ (ext_util_range .* sigma .* sqrt(2*pi)))
    #pdf = pdf / sum(pdf)

    gen = () -> sample(ext_util_range, ProbabilityWeights(pdf))
    return Dict((item -> item => gen()).(items))
end

function gen_int_util(transactions::Vector{Set{String}}, int_util_range::UnitRange{Int})::Vector{Dict{String, Int}}
    gen = () -> rand(int_util_range)
    return (trans -> Dict((item -> item => gen()).(trans))).(transactions)
end

function gen_int_util(transactions::Vector{Set{String}}, utilTable::Dict{String, Int}, int_util_range::UnitRange{Int})::Tuple{Vector{Dict{String, Int}}, Int}
    util_transactions = Vector{Dict{String, Int}}(undef, length(transactions))
    total_util = 0

    for (tid, trans) in enumerate(transactions)
        util_trans = Dict{String, Int}()
        for item in trans
            int_util = rand(int_util_range)
            util_trans[item] = int_util
            total_util += int_util * utilTable[item]
        end
        util_transactions[tid] = util_trans
    end

    return (util_transactions, total_util)
end

function gen_dataset(name::String, transactions::Vector{Set{String}}, int_util_range::UnitRange{Int}, ext_util_range::UnitRange{Int})::Dataset
    items = reduce(union, transactions)
    utilTable = gen_ext_util(items, ext_util_range)
    util_transactions, total_util = gen_int_util(transactions, utilTable, int_util_range)

    Dataset(name, util_transactions, utilTable, items, total_util)
end