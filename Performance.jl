using JSON

const Metrics = Dict{String, Float64}

struct Performance
    name::String
    data::Dict{Float64, Dict{Float64, Dict{String, Metrics}}}
end

function Performance(perf_name::String)
    Performance(perf_name, Dict{Float64, Dict{Float64, Dict{String, Metrics}}}())
end

function add!(perf::Performance, mut::Float64, sip::Float64, alg::String, metrics::Metrics)
    if !haskey(perf.data, mut)
        perf.data[mut] = Dict{Float64, Dict{String, Metrics}}()
    end

    if !haskey(perf.data[mut], sip)
        perf.data[mut][sip] = Dict{String, Metrics}()
    end

    perf.data[mut][sip][alg] = metrics
end

function add!(perf::Performance, mut::Float64, sip::Float64, algs_metrics::Dict{String, Metrics})
    for (alg, metrics) in algs_metrics
        add!(perf, mut, sip, alg, metrics)
    end
end

function Base.get(perf::Performance, mut::Float64, sips::Vector{Float64}, field::String)
    fields = Dict{String, Vector{Float64}}()
    
    for (i, sip) in enumerate(sips)
        for (alg, metrics) in perf.data[mut][sip]
            if !haskey(fields, alg)
                fields[alg] = Vector{Float64}(undef, length(sips))
            end
            fields[alg][i] = metrics[field]
        end
    end
    
    return fields
end

function Base.get(perf::Performance, muts::Vector{Float64}, sip::Float64, field::String)
    fields = Dict{String, Vector{Float64}}()
    
    for (i, mut) in enumerate(muts)
        for (alg, metrics) in perf.data[mut][sip]
            if !haskey(fields, alg)
                fields[alg] = Vector{Float64}(undef, length(muts))
            end
            fields[alg][i] = metrics[field]
        end
    end
    
    return fields
end

function save(perf::Performance)
    open("./Performances/$(perf.name).json", "w") do io
        JSON.print(io, perf.data, 4)
    end
end

function load_performance(perf_name::String)
    path = "./Performances/$(perf_name).json"
    @assert isfile(path) "Performance($(perf_name)) does not exist"

    data = JSON.parsefile(path)
    perf = Performance(perf_name)

    for (mut, sip_data) in data
        for (sip, alg_data) in sip_data
            for (alg, metrics) in alg_data
                # Chuyển đổi metrics thành Dict{String, Float64}
                converted_metrics = Dict{String, Float64}(k => Float64(v) for (k, v) in metrics)
                add!(perf, parse(Float64, mut), parse(Float64, sip), alg, converted_metrics)
            end
        end
    end

    return perf
end