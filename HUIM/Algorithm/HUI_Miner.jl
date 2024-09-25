#=
# Định nghĩa cấu trúc dữ liệu
struct Element
    tid::Int
    iutil::Int
    rutil::Int
end

struct UtilityList
    item::String
    sumIutils::Int
    sumRutils::Int
    elements::Vector{Element}
end

# Hàm tạo utility-list cho một mục
function construct_utility_list(transactions, util_table, item)
    elements = Element[]
    sum_iutils = 0
    sum_rutils = 0
    
    for (tid, transaction) in enumerate(transactions)
        if haskey(transaction, item)
            iutil = transaction[item] * util_table[item]
            rutil = sum(transaction[i] * util_table[i] for i in keys(transaction) if i < item; init=0)
            push!(elements, Element(tid, iutil, rutil))
            sum_iutils += iutil
            sum_rutils += rutil
        end
    end
    
    return UtilityList(item, sum_iutils, sum_rutils, elements)
end

# Hàm nối hai utility-list
function construct_utility_list(P::UtilityList, Px::UtilityList)
    elements = Element[]
    sum_iutils = 0
    sum_rutils = 0
    
    for ep in P.elements
        ex = findfirst(e -> e.tid == ep.tid, Px.elements)
        if ex !== nothing
            e = Px.elements[ex]
            eutil = ep.iutil + e.iutil
            push!(elements, Element(ep.tid, eutil, e.rutil))
            sum_iutils += eutil
            sum_rutils += e.rutil
        end
    end
    
    return UtilityList(Px.item, sum_iutils, sum_rutils, elements)
end

# Hàm chính của HUI-Miner
function hui_miner(transactions::Vector{Dict{String, Int}}, util_table::Dict{String, Int}, min_util::Int)
    # Tạo utility-list cho các mục đơn lẻ
    ul_list = [construct_utility_list(transactions, util_table, item) for item in keys(util_table)]
    
    # Sắp xếp theo thứ tự TWU giảm dần
    sort!(ul_list, by = ul -> ul.sumIutils + ul.sumRutils, rev=true)
    
    # Loại bỏ các mục có TWU < min_util
    filter!(ul -> ul.sumIutils + ul.sumRutils >= min_util, ul_list)
    
    hui = Dict{Vector{String}, Int}()
    
    # Hàm đệ quy để khai thác HUI
    function mine(P::Vector{UtilityList}, ULs::Vector{UtilityList}, prefix::Vector{String})
        for i in 1:length(ULs)
            X = ULs[i]
            if X.sumIutils >= min_util
                push!(hui, vcat(prefix, [X.item]) => X.sumIutils)
            end
            if X.sumIutils + X.sumRutils >= min_util
                exULs = UtilityList[]
                for j in (i+1):length(ULs)
                    Y = ULs[j]
                    Pxy = construct_utility_list(X, Y)
                    if Pxy.sumIutils + Pxy.sumRutils >= min_util
                        push!(exULs, Pxy)
                    end
                end
                mine(vcat(P, [X]), exULs, vcat(prefix, [X.item]))
            end
        end
    end
    
    mine(UtilityList[], ul_list, String[])
    return hui
end

# Sử dụng hàm
# transactions = [Dict("A" => 1, "B" => 2, "C" => 3), Dict("B" => 4, "C" => 5, "D" => 6)]
# util_table = Dict("A" => 5, "B" => 2, "C" => 1, "D" => 2)
# min_util = 20
# result = hui_miner(transactions, util_table, min_util)
# println(result)

=#

#=
struct UtilityList1
    tid::Vector{Int}
    iutil::Vector{Int}
    rutil::Vector{Int}
end

function construct_utility_lists(transactions::Vector{Dict{String, Int}}, utility_table::Dict{String, Int})
    utility_lists = Dict{String, UtilityList1}()
    
    for (tid, transaction) in enumerate(transactions)
        transaction_utility = sum(quantity * utility_table[item] for (item, quantity) in transaction)
        
        remaining_utility = transaction_utility
        sorted_items = sort(collect(keys(transaction)))
        for item in sorted_items
            quantity = transaction[item]
            if !haskey(utility_lists, item)
                utility_lists[item] = UtilityList1([], [], [])
            end
            
            item_utility = quantity * utility_table[item]
            push!(utility_lists[item].tid, tid)
            push!(utility_lists[item].iutil, item_utility)
            push!(utility_lists[item].rutil, remaining_utility - item_utility)
            
            remaining_utility -= item_utility
        end
    end
    
    return utility_lists
end

function construct_utility_list(P::UtilityList1, Px::UtilityList1, Py::UtilityList1)
    Pxy = UtilityList1([], [], [])
    
    i, j = 1, 1
    while i <= length(Px.tid) && j <= length(Py.tid)
        if Px.tid[i] == Py.tid[j]
            push!(Pxy.tid, Px.tid[i])
            push!(Pxy.iutil, Px.iutil[i] + Py.iutil[j])
            push!(Pxy.rutil, Py.rutil[j])
            i += 1
            j += 1
        elseif Px.tid[i] < Py.tid[j]
            i += 1
        else
            j += 1
        end
    end
    
    return Pxy
end

function hui_miner(transactions::Vector{Dict{String, Int}}, utility_table::Dict{String, Int}, min_utility::Int)
    utility_lists = construct_utility_lists(transactions, utility_table)
    hui = Dict{Set{String}, Int}()
    
    function search(itemset::Set{String}, ul::UtilityList1, extensions::Vector{Pair{String, UtilityList1}})
        total_utility = sum(ul.iutil)
        if total_utility >= min_utility
            hui[itemset] = total_utility
        end
        
        for i in 1:length(extensions)
            item_i, ul_i = extensions[i]
            new_itemset = union(itemset, Set([item_i]))
            new_ul = construct_utility_list(ul, ul, ul_i)
            if sum(new_ul.iutil) + sum(new_ul.rutil) >= min_utility
                new_extensions = extensions[(i+1):end]
                search(new_itemset, new_ul, new_extensions)
            end
        end
    end
    
    sorted_items = sort(collect(keys(utility_lists)), 
                        by=item -> sum(utility_lists[item].iutil), 
                        rev=true)
    
    for i in 1:length(sorted_items)
        item_i = sorted_items[i]
        ul_i = utility_lists[item_i]
        if sum(ul_i.iutil) >= min_utility
            hui[Set([item_i])] = sum(ul_i.iutil)
        end
        extensions = [item => utility_lists[item] for item in sorted_items[(i+1):end]]
        search(Set([item_i]), ul_i, extensions)
    end
    
    return hui
end

#=
# Test với dữ liệu mẫu
transactions = [
    Dict("C" => 7, "D" => 1, "E" => 1),
    Dict("A" => 1, "C" => 2, "E" => 2),
    Dict("B" => 6, "C" => 4, "D" => 3, "E" => 7),
    Dict("B" => 5, "C" => 3, "D" => 9),
    Dict("A" => 3, "C" => 10, "D" => 3),
    Dict("C" => 5, "E" => 9),
    Dict("A" => 6, "C" => 9, "D" => 2, "E" => 5),
    Dict("A" => 1, "B" => 6, "C" => 2, "D" => 5, "E" => 3)
]

utility_table = Dict("A" => 9, "B" => 11, "C" => 4, "D" => 6, "E" => 7)
min_utility = 200

result = hui_miner(transactions, utility_table, min_utility)
println("High Utility Itemsets with their utilities:")
for (itemset, utility) in sort(collect(result), by=x->x[2], rev=true)
    println("$itemset: $utility")
end
=#
=#

using DataStructures

struct Element
    iutils::Int
    rutils::Int
end

mutable struct Data
    t_iutils::Int
    t_rutils::Int
    tidset::Set{Int}
    elements::Dict{Int, Element}
    prune::Bool
end

Data() = Data(0, 0, Set{Int}(), Dict{Int, Element}(), false)

mutable struct UtilityList1
    prefix_util::Union{Nothing, Dict{Int, Element}}
    prefix::Vector{String}
    data::OrderedDict{String, Data}
end

UtilityList1() = UtilityList1(nothing, String[], OrderedDict{String, Data}())

function add_item_to_ul(ul::UtilityList1, item::String)
    ul.data[item] = Data()
end

function add_element(ul::UtilityList1, item::String, tid::Int, iutils::Int, rutils::Int)
    d = ul.data[item]
    d.t_iutils += iutils
    d.t_rutils += rutils
    d.elements[tid] = Element(iutils, rutils)
    push!(d.tidset, tid)
end

function construct_1_utilitylist(transactions::Vector{Dict{String, Int}}, utility_table::Dict{String, Int}, min_utility::Int)
    twu = DefaultDict{String, Int}(0)
    transaction_utilities = Dict{Int, Int}()
    total_utility = 0

    for (tid, transaction) in enumerate(transactions)
        t_utility = sum(quantity * utility_table[item] for (item, quantity) in transaction)
        transaction_utilities[tid] = t_utility
        total_utility += t_utility
        for item in keys(transaction)
            twu[item] += t_utility
        end
    end

    sorted_items = sort(collect(keys(twu)), by=item -> twu[item], rev=true)
    ul = UtilityList1()

    for item in sorted_items
        add_item_to_ul(ul, item)
        for (tid, transaction) in enumerate(transactions)
            if haskey(transaction, item)
                iutils = transaction[item] * utility_table[item]
                rutils = transaction_utilities[tid] - iutils
                add_element(ul, item, tid, iutils, rutils)
            end
        end
    end

    return ul, total_utility
end

function construct_k_utilitylist(ul::UtilityList1, min_utility::Int)
    new_uls = UtilityList1[]
    items = collect(keys(ul.data))
    n = length(items)

    for i in 1:n-1
        a = items[i]
        if ul.data[a].prune
            continue
        end

        new_prefix = vcat(ul.prefix, a)
        new_ul = UtilityList1(ul.data[a].elements, new_prefix, OrderedDict{String, Data}())

        for j in i+1:n
            b = items[j]
            t_a = ul.data[a].tidset
            t_b = ul.data[b].tidset

            trans = intersect(t_a, t_b)
            if isempty(trans)
                continue
            end

            add_item_to_ul(new_ul, b)

            for t in trans
                iutils = ul.data[a].elements[t].iutils + ul.data[b].elements[t].iutils
                if !isnothing(ul.prefix_util)
                    iutils -= ul.prefix_util[t].iutils
                end
                rutils = ul.data[b].elements[t].rutils

                add_element(new_ul, b, t, iutils, rutils)
            end

            utils = new_ul.data[b].t_iutils
            r_utils = new_ul.data[b].t_rutils

            if utils + r_utils < min_utility
                new_ul.data[b].prune = true
            end
        end

        push!(new_uls, new_ul)
    end

    return new_uls
end

function hui_miner(transactions::Vector{Dict{String, Int}}, utility_table::Dict{String, Int}, min_utility::Int)
    h_sets = Dict{Vector{String}, Int}()
    ul, total_utility = construct_1_utilitylist(transactions, utility_table, min_utility)

    for (item, data) in ul.data
        if data.t_iutils ≥ min_utility
            push!(h_sets, [item] => data.t_iutils)
        end
        if data.t_iutils + data.t_rutils < min_utility
            data.prune = true
        end
    end

    uls = [ul]
    k = 2

    while !isempty(uls)
        new_uls = UtilityList1[]
        for ul in uls
            k_uls = construct_k_utilitylist(ul, min_utility)
            for k_ul in k_uls
                for (item, data) in k_ul.data
                    if data.t_iutils ≥ min_utility
                        push!(h_sets, vcat(k_ul.prefix, item) => data.t_iutils)
                    end
                end
            end
            append!(new_uls, k_uls)
        end
        uls = new_uls
        k += 1
    end

    # return h_sets #, total_utility
    return Dict(Set(k) => v for (k, v) in h_sets)
end

#=
transactions = [
    Dict("C" => 7, "D" => 1, "E" => 1),
    Dict("A" => 1, "C" => 2, "E" => 2),
    Dict("B" => 6, "C" => 4, "D" => 3, "E" => 7),
    Dict("B" => 5, "C" => 3, "D" => 9),
    Dict("A" => 3, "C" => 10, "D" => 3),
    Dict("C" => 5, "E" => 9),
    Dict("A" => 6, "C" => 9, "D" => 2, "E" => 5),
    Dict("A" => 1, "B" => 6, "C" => 2, "D" => 5, "E" => 3)
]

utility_table = Dict("A" => 9, "B" => 11, "C" => 4, "D" => 6, "E" => 7)
min_utility = 200

result, total_utility = hui_miner(transactions, utility_table, min_utility)
println("Total Utility: $total_utility")
println("High Utility Itemsets:")
for (itemset, utility) in result
    println("$itemset: $utility")
end
=#