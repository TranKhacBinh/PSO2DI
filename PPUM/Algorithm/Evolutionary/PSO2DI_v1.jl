include("../../../HUIM/Utility.jl")

function initialize_particle_v1(particle_size::Int)
    return Set(rand(1:particle_size, particle_size))
end

function fitness_v1(particle::Set{Int}, n_S::Int, utility_table::Vector{Vector{Int}}, min_util::Int, w1::Float64, w2::Float64)
    new_util = utility_table[end] .- sum(utility_table[i] for i in particle)
    HF = sum(new_util[1:n_S] .>= min_util)
    MC = sum(new_util[n_S + 1: end] .< min_util)
    
    return w1 * HF + w2 * MC
end

function update_velocity_v1(particles::Vector{Set{Int}}, pbests::Vector{Set{Int}}, gbest::Set{Int})
    return [union(setdiff(pbest, particle), setdiff(gbest, particle)) for (particle, pbest) in zip(particles, pbests)]
end

function update_particle_v1(velocitys::Vector{Set{Int}}, particle_size::Int)
    (v -> push!(v, rand(1:particle_size))).(velocitys)
    return velocitys
end

function PSO2DI_v1(transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int}, S::Set{Set{String}},
    HUIs::Dict{Set{String}, Int}, min_util::Int, M::Int, max_iterations::Int, w1::Float64, w2::Float64)

	s_tids = findall(trans -> any(s -> issubset(s, keys(trans)), S), transactions)
	NS = setdiff(Set(keys(HUIs)), S)
	SI = reduce(union, S)

    f = Dict{String, Set{Set{String}}}(item => Set{Set{String}}() for item in SI)
    for itemset in NS
        for item in intersect(itemset, SI)
            push!(f[item], itemset)
        end
    end

    g = Dict{Set{String}, String}()
    for s in S
        min_item = nothing
        min_length = typemax(Int)
        for item in s
            item_length = length(f[item])
            if item_length == 0
                min_item = item
                break
            elseif item_length < min_length
                min_item = item
                min_length = item_length
            end
        end
        g[s] = min_item
    end

	PMC = reduce(union, [f[g[s]] for s in S])
    S_PMC = append!(collect(S), PMC)

    utility_table = [Vector{Int}(undef, length(S_PMC)) for _ in 1:length(s_tids)]
    for (i, s_tid) in enumerate(s_tids)
        for (j, itemset) in enumerate(S_PMC)
            utility_table[i][j] = utility(itemset, transactions[s_tid], utilTable)
        end
    end
    push!(utility_table, [HUIs[itemset] for itemset in S_PMC])

    n_S = length(S)
    particle_size = length(s_tids)

	particles = [initialize_particle_v1(particle_size) for _ in 1:M]

    pbests = particles
    pbests_fitness = [fitness_v1(p, n_S, utility_table, min_util, w1, w2) for p in pbests]

    gbest_index = argmin(pbests_fitness)
    gbest = pbests[gbest_index]
    gbest_fitness = pbests_fitness[gbest_index]

    velocitys = update_velocity_v1(particles, pbests, gbest)
    particles = update_particle_v1(velocitys, particle_size)
    
    for _ in 1:max_iterations
        for i in 1:M
            pi_fitness = fitness_v1(particles[i], n_S, utility_table, min_util, w1, w2)
			
            if pi_fitness < pbests_fitness[i]
                pbests[i] = particles[i]
                pbests_fitness[i] = pi_fitness

                if pbests_fitness[i] < gbest_fitness
                    gbest = pbests[i]
                    gbest_fitness = pbests_fitness[i]
                end
            end
        end
        
        velocitys = update_velocity_v1(particles, pbests, gbest)
        particles = update_particle_v1(velocitys, particle_size)
    end

	sanitized_transactions = deepcopy(transactions)
    for i in gbest
        for j in 1:n_S
            if utility_table[i][j] > 0
                delete!(sanitized_transactions[s_tids[i]], g[S_PMC[j]])
            end
        end

        #=
        if isempty(sanitized_transactions[s_tids[i]])
            deleteat!(sanitized_transactions, s_tids[i])
        end
        =#
    end

    return filter!(trans -> !isempty(trans), sanitized_transactions)
end