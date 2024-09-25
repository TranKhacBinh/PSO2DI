function utility(item::String, trans::Dict{String, Int}, utilTable::Dict{String, Int})
	return trans[item] * utilTable[item]
end

function utility(itemset::Set{String}, trans::Dict{String, Int}, utilTable::Dict{String, Int})
	total_util = 0
	for item in itemset
		int_util = get(trans, item, nothing)
		if int_util === nothing
			return 0
		end
		total_util += int_util * utilTable[item]
	end
	return total_util
end

function utility(itemset::Set{String}, transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int})
    return sum(utility(itemset, trans, utilTable) for trans in transactions)
end

function utility(trans::Dict{String, Int}, utilTable::Dict{String, Int})
	return sum(int_util * utilTable[item] for (item, int_util) in pairs(trans))
end

function utility(transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int})
	return sum(utility(trans, utilTable) for trans in transactions)
end