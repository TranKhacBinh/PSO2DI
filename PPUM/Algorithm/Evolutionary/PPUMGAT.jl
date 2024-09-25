include("../../../HUIM/Utility.jl")
using Random

# Hàm tính TWU (Transaction-Weighted Utility)
function calculate_twu(itemset::Set{String}, transactions::Vector{Dict{String, Int}}, tu::Vector{Int})
    sum(tu[tid] for (tid, trans) in enumerate(transactions) if all(item in keys(trans) for item in itemset); init=0)
end

function calculate_mdu(S::Set{Set{String}}, transactions::Vector{Dict{String, Int}}, tu::Vector{Int}, min_util::Int)
    return sum(calculate_twu(s, transactions, tu) - min_util for s in S; init=0)
end

function find_candi_delete(transactions::Vector{Dict{String, Int}}, S::Set{Set{String}}, tu::Vector{Int}, mdu::Int)
    candidates = Vector{Int}()
    for (tid, trans) in enumerate(transactions)
        if any(all(item in keys(trans) for item in s) for s in S)
            if tu[tid] < mdu
                push!(candidates, tid)
            end
        end
    end
    return sort(candidates, by=x->tu[x])
end

function initialize_population(candidates::Vector{Int}, chromosome_length::Int, population_size::Int)
    return [randperm(length(candidates))[1:chromosome_length] for _ in 1:population_size]
end

function crossover(parent1::Vector{Int}, parent2::Vector{Int})
    crossover_point = rand(1:length(parent1))
    child = vcat(parent1[1:crossover_point], parent2[crossover_point+1:end])
    return unique(child)
end

function mutate(chromosome::Vector{Int}, candidates::Vector{Int})
    if rand() < 0.25  # mutation probability
        idx = rand(1:length(chromosome))
        chromosome[idx] = rand(1:length(candidates))
    end
    return unique(chromosome)
end

function fitness(chromosome::Vector{Int}, utility_table::Dict{Set{String}, Vector{Int}}, S::Set{Set{String}},
                NS::Set{Set{String}}, HUIs::Dict{Set{String}, Int}, min_util::Int, w1::Float64, w2::Float64)
    
    HF = sum((HUIs[s] - sum(utility_table[s][index] for index in chromosome)) >= min_util for s in S; init=0)
    MC = sum((HUIs[ns] - sum(utility_table[ns][index] for index in chromosome)) < min_util for ns in NS; init=0)
    
    return w1 * HF + w2 * MC
end

function ppumgat(transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int}, S::Set{Set{String}},
                HUIs::Dict{Set{String}, Int}, min_util::Int, population_size::Int, max_generations::Int, w1::Float64, w2::Float64)

    NS = setdiff(Set(keys(HUIs)), S)
    tu = (trans -> utility(trans, utilTable)).(transactions)
    mdu = calculate_mdu(S, transactions, tu, min_util)
    candidates = find_candi_delete(transactions, S, tu, mdu)

    utility_table = Dict(itemset => [utility(itemset, transactions[tid], utilTable) for tid in candidates] for itemset in keys(HUIs))


    chromosome_length = 0
    total_utility = 0
    for tid in candidates
        total_utility += tu[tid]
        if total_utility > mdu
            break
        end
        chromosome_length += 1
    end
    
    population = initialize_population(candidates, chromosome_length, population_size)
    
    for _ in 1:max_generations
        # Crossover and Mutation
        new_population = [mutate(crossover(chromosome, rand(population)), candidates) for chromosome in population]
        
        # Evaluate fitness
        fitness_scores = [fitness(chromosome, utility_table, S, NS, HUIs, min_util, w1, w2) for chromosome in new_population]
        
        # Selection
        population = new_population[sortperm(fitness_scores)[1:div(population_size, 2)]]
        
        # Generate new random chromosomes
        append!(population, initialize_population(candidates, chromosome_length, population_size - div(population_size, 2)))
    end
    
    best_chromosome = population[argmin([fitness(chromosome, utility_table, S, NS, HUIs, min_util, w1, w2) for chromosome in population])]
    deleted_tid = candidates[best_chromosome]
    
    return [trans for (tid, trans) in enumerate(transactions) if !(tid in deleted_tid)]
end

#=
transactions = [
	Dict("D" => 6, "F" => 1),
    Dict("E" => 6),
	Dict("A" => 5, "E" => 1),
	Dict("B" => 5, "F" => 2),
	Dict("C" => 8, "F" => 2),
	Dict("A" => 4, "E" => 1),
	Dict("B" => 2, "C" => 3, "D" => 2),
	Dict("A" => 7, "B" => 3, "E" => 2),
	Dict("E" => 4),
	Dict("A" => 5, "B" => 2, "E" => 5),
	Dict("C" => 1, "F" => 1),
	Dict("A" => 3, "E" => 3)
]

utilTable = Dict("A" => 7, "B" => 15, "C" => 10, "D" => 6, "E" => 2, "F" => 1)

S = Set([Set(["B"]), Set(["A", "B", "E"])])

HUIs = Dict(
	Set(["A"]) => 168,
	Set(["B"]) => 180,
	Set(["C"]) => 120,
    Set(["A", "B"]) => 159,
	Set(["A", "E"]) => 192,
	Set(["A", "B", "E"]) => 173
)

min_util = 114

runtime = @elapsed sanitized_transactions = ppumgat(transactions, utilTable, S, HUIs, min_util, 4, 10, 0.8, 0.2)

include("../../../HUIM/Algorithm/D2HUP.jl")
include("../../SideEffects.jl")

sanitized_HUIs = d2hup(sanitized_transactions, utilTable, min_util)
se = SideEffects(S, HUIs, sanitized_HUIs)

println("min_util = ", min_util)
println("|HUIs| = ", length(HUIs))
println("|S| = ", length(S))
println("Runtime = ", runtime, " (seconds)")
se
=#


