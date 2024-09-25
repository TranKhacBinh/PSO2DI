include("../../../HUIM/Utility.jl")

function calculate_utility_table(trans_db, ext_util, s_tids, S_PMC, HUIs)
    utility_table = Dict()
	for s_tid in s_tids
		utility_table[s_tid] = [utility(itemset, trans_db[s_tid], ext_util) for itemset in S_PMC]
	end
	utility_table["total"] = [HUIs[itemset] for itemset in S_PMC]
    return utility_table
end

function initialize_particle(s_tids)
    return Set(rand(s_tids, length(s_tids)))
end

function fitness_function(particle, S, PMC, f, g, utility_table, index, delta, w1, w2)
	copy_util_table = deepcopy(utility_table)
	for s_tid in particle
		for s in S
			if copy_util_table[s_tid][index[s]] > 0
				copy_util_table["total"][index[s]] -= copy_util_table[s_tid][index[s]]
				pmc_index = [index[itemset] for itemset in f[g[s]]]
				@views copy_util_table["total"][pmc_index] .-= copy_util_table[s_tid][pmc_index]
				@views copy_util_table[s_tid][pmc_index] .= 0
			end
		end
	end

	HF = sum(copy_util_table["total"][index[s]] >= delta for s in S; init=0)
	MC = sum(copy_util_table["total"][index[pmc]] < delta for pmc in PMC; init=0)
    
    return w1 * HF + w2 * MC
end

function update_velocity(particles, pbests, gbest)
    return map(union, map(setdiff, pbests, particles), map(p -> setdiff(gbest, p), particles))
end

function update_particle(velocitys, s_tids)
    return map(v -> union(Set(rand(s_tids)), v), velocitys)
end

function PSO2DI(trans_db, ext_util, S, HUIs, delta, M, max_iterations, w1, w2)
	s_tids = [
	    tid for (tid, trans) in enumerate(trans_db)
	    if any(all(haskey(trans, item) for item in s) for s in S)
	]
	
	NS = setdiff(Set(keys(HUIs)), S)
	SI = Set(item for s in S for item in s)

	f = Dict(
		item => Set(
			itemset for itemset in NS
			if item in itemset
		)
		for item in SI
	)

	g = Dict(
		s => argmin(
			Dict(item => length(f[item]) for item in s)
		)
		for s in S
	)

	PMC = reduce(union, [f[g[s]] for s in S])
	S_PMC = collect(union(S, PMC))
	index = Dict(value => index for (index, value) in enumerate(S_PMC))

	utility_table = calculate_utility_table(trans_db, ext_util, s_tids, S_PMC, HUIs)
	particles = [initialize_particle(s_tids) for _ in 1:M]

	fitness = Dict(p => fitness_function(p, S, PMC, f, g, utility_table, index, delta, w1, w2) for p in particles)

	pbests = deepcopy(particles)
    gbest = pbests[argmin([fitness[p] for p in pbests])]
    
    
    for _ in 1:max_iterations
        for i in 1:M
			if !haskey(fitness, particles[i])
				fitness[particles[i]] = fitness_function(particles[i], S, PMC, f, g, utility_table, index, delta, w1, w2)
			end
			
            if fitness[particles[i]] < fitness[pbests[i]]
                pbests[i] = particles[i]
            end
            
            if fitness[pbests[i]] < fitness[gbest]
                gbest = pbests[i]
            end
        end
        
        velocitys = update_velocity(particles, pbests, gbest)
        particles = update_particle(velocitys, s_tids)
    end

	#print((gbest, fitness[gbest]))

	sanitized_trans_db = deepcopy(trans_db)
    for tid in gbest
        for s in S
            if utility_table[tid][index[s]] > 0
				delete!(sanitized_trans_db[tid], g[s])
			end
        end
    end
    
    return sanitized_trans_db
end