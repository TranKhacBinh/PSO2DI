include("../Utility.jl")

function calculate_twu(itemsets::Vector{Set{String}}, transactions::Vector{Dict{String, Int}}, tus::Vector{Int})
    itemsets_twu = Dict{Set{String}, Int}()
    for (tid, transaction) in enumerate(transactions)
        transaction_items = Set(keys(transaction))
        for itemset in itemsets
            if issubset(itemset, transaction_items)
                itemsets_twu[itemset] = get(itemsets_twu, itemset, 0) + tus[tid]
            end
        end
    end
    return itemsets_twu
end

# Hàm tạo ứng viên k-itemset từ (k-1)-itemset
function generate_candidates(prev_candidates::Vector{Set{String}}, k::Int)
    candidates = Set{Set{String}}()
    for i in 1:length(prev_candidates)
        for j in (i+1):length(prev_candidates)
            c1 = prev_candidates[i]
            c2 = prev_candidates[j]
            if length(setdiff(c1, c2)) == 1
                new_candidate = union(c1, c2)
                if length(new_candidate) == k
                    push!(candidates, new_candidate)
                end
            end
        end
    end
    return collect(candidates)
end

# Giai đoạn 1: Tìm kiếm các ứng viên
function phase1(transactions::Vector{Dict{String, Int}}, items::Set{String}, tus::Vector{Int}, min_util::Int)
    candidates = Vector{Set{String}}()

    k = 1
    k_itemsets = (item -> Set([item])).(collect(items))
    k_itemsets_twu = calculate_twu(k_itemsets, transactions, tus)
    k_candidates = [k_itemset for (k_itemset, twu) in k_itemsets_twu if twu >= min_util]

    while !isempty(k_candidates)
        append!(candidates, k_candidates)

        k += 1
        k_itemsets = generate_candidates(k_candidates, k)
        k_itemsets_twu = calculate_twu(k_itemsets, transactions, tus)
        k_candidates = [k_itemset for (k_itemset, twu) in k_itemsets_twu if twu >= min_util]
    end

    return candidates
end

# Giai đoạn 2: Xác định các tập có độ hữu ích cao thực sự
function phase2(transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int}, candidates::Vector{Set{String}}, min_util::Int)
    HUIs = Dict{Set{String}, Int}()
    for candidate in candidates
        candidate_util = utility(candidate, transactions, utilTable)
        if candidate_util >= min_util
            HUIs[candidate] = candidate_util
        end
    end
    return HUIs
end

function two_phase(transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int}, items::Set{String}, min_util::Int)
    tus = (transaction -> utility(transaction, utilTable)).(transactions)
    candidates = phase1(transactions, items, tus, min_util)
    HUIs = phase2(transactions, utilTable, candidates, min_util)
    return HUIs
end