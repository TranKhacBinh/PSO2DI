using Statistics

struct Dataset
    name::String

    transactions::Vector{Dict{String, Int}}
    utilTable::Dict{String, Int}
    items::Set{String}

    n_trans::Int
    n_items::Int
    avg_trans_len::Float64
    density::Float64
    int_util_range::UnitRange{Int}
    ext_util_range::UnitRange{Int}
    total_util::Ref{Union{Int, Missing}}

    mut::Ref{Union{Float64, Missing}}
    huis::Ref{Union{Dict{Set{String}, Int}, Missing}}
end

function Base.show(io::IO, ds::Dataset)
    println(io, "Dataset:
    name = $(ds.name)
    n_trans = $(ds.n_trans)
    n_items = $(ds.n_items)
    avg_trans_len = $(ds.avg_trans_len)
    density = $(ds.density)
    int_util_range = $(ds.int_util_range)
    ext_util_range = $(ds.ext_util_range)
    total_util = $(ds.total_util[])
    mut = $(ds.mut[])")
end

function Dataset(name::String, transactions::Vector{Dict{String, Int}}, utilTable::Dict{String, Int},
    items::Union{Set{String}, Missing} = missing, total_util::Union{Int, Missing} = missing, mut::Union{Float64, Missing} = missing,
    huis::Union{Dict{Set{String}, Int}, Missing} = missing)

    if ismissing(items)
        items = reduce(union, keys.(transactions))
        @assert items == keys(utilTable) "Invalid dataset"
    end

    n_trans = length(transactions)
    n_items = length(items)
    avg_trans_len = round(mean(length.(transactions)), digits=2)
    density = round((avg_trans_len / n_items) * 100, digits=2)
    int_util_range = (x -> minimum(minimum.(x)):maximum(maximum.(x)))(values.(transactions))
    ext_util_range = (x -> minimum(x):maximum(x))(values(utilTable))

    return Dataset(name, transactions, utilTable, items, n_trans, n_items, avg_trans_len, density, int_util_range, ext_util_range,
    Ref{Union{Int, Missing}}(total_util), Ref{Union{Float64, Missing}}(mut), Ref{Union{Dict{Set{String}, Int}, Missing}}(huis))
end

str_to_pair = s -> begin
    pair = split(s, ',')
    Pair(String(pair[1]), parse(Int, pair[2]))
end

function load_transactions(path::String)
    lines = readlines(path)

    if ',' in lines[1]
        Dict.((line -> str_to_pair.(split(line))).(lines))
    else
        Set.((line -> String.(split(line))).(lines))
    end
end

function load_utilTable(path::String)
    lines = readlines(path)
    Dict(str_to_pair.(lines))
end

function load_huis(path::String)
    lines = readlines(path)
    Dict((line -> (pair -> Set(String.(split(pair[1]))) => parse(Int, pair[2]))(split(line, ", "))).(lines))
end

function load_info(path::String)
    lines = readlines(path)

    name = lines[1]
    n_trans = parse(Int, lines[2])
    n_items = parse(Int, lines[3])
    avg_trans_len = parse(Float64, lines[4])
    density = parse(Float64, lines[5])
    int_util_range = (s -> parse(Int, s[1]):parse(Int, s[2]))(split(lines[6], ":"))
    ext_util_range = (s -> parse(Int, s[1]):parse(Int, s[2]))(split(lines[7], ":"))
    total_util = lines[8] == "missing" ? missing : parse(Int, lines[8])
    mut = lines[9] == "missing" ? missing : parse(Float64, lines[9])

    return (name, n_trans, n_items, avg_trans_len, density, int_util_range, ext_util_range, total_util, mut)
end

function load_dataset(dataset_name::String, path::String = "./Datasets")
    dataset_path = "$(path)/$(dataset_name)"
    @assert isdir(dataset_path) "Dataset does not exist"

    name, n_trans, n_items, avg_trans_len, density, int_util_range, ext_util_range, total_util, mut = load_info("$(dataset_path)/info.txt")
    @assert dataset_name == name "Invalid dataset"

    transactions = load_transactions("$(dataset_path)/transactions.txt")
    utilTable = load_utilTable("$(dataset_path)/utilTable.txt")

    huis = missing
    if !ismissing(mut)
        huis = load_huis("$(dataset_path)/huis.txt")
    end
    
    return Dataset(name, transactions, utilTable, Set(keys(utilTable)), n_trans, n_items, avg_trans_len, density, int_util_range, ext_util_range,
    Ref{Union{Int, Missing}}(total_util), Ref{Union{Float64, Missing}}(mut), Ref{Union{Dict{Set{String}, Int}, Missing}}(huis))
end

function writelines(vector::Vector{String}, path::String)
    open(path, "w") do file
        (elem -> println(file, elem)).(vector)
    end
end

function save(transactions::Vector{Set{String}}, path::String)
    strings = join.(transactions, " ")
    writelines(strings, path)
end

function save(transactions::Vector{Dict{String, Int}}, path::String)
    strings = (trans -> join((pair -> join(pair, ",")).(collect(trans)), " ")).(transactions)
    writelines(strings, path)
end

function save(utilTable::Dict{String, Int}, path::String)
    strings = (pair -> join(pair, ", ")).(collect(utilTable))
    writelines(strings, path)
end

function save(huis::Dict{Set{String}, Int}, path::String)
    strings = (pair -> "$(join(pair[1], " ")), $(pair[2])").(collect(huis))
    writelines(strings, path)
end

function save(dataset::Dataset, path::String = "./Datasets", new_name::Union{String, Missing} = missing)
    if ismissing(new_name)
        new_name = dataset.name
    end

    dataset_path = "$(path)/$(new_name)"

    if !isdir(dataset_path)
        mkdir(dataset_path)
    end

    info = [new_name, dataset.n_trans, dataset.n_items, dataset.avg_trans_len, dataset.density,
            dataset.int_util_range, dataset.ext_util_range, dataset.total_util[], dataset.mut[]]

    writelines(string.(info), "$(dataset_path)/info.txt")
    save(dataset.transactions, "$(dataset_path)/transactions.txt")
    save(dataset.utilTable, "$(dataset_path)/utilTable.txt")

    if !ismissing(dataset.huis[])
        save(dataset.huis[], "$(dataset_path)/huis.txt")
    end
end

function Base.:(==)(a::Dataset, b::Dataset)
    fields = fieldnames(Dataset)
    all(getfield(a, field) == getfield(b, field) for field in fields[1:10]) && 
    all(isequal(getfield(a, field)[], getfield(b, field)[]) for field in fields[11:end])
end