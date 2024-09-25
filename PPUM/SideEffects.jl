struct SideEffects
    HF::Float64
    MC::Float64
    AC::Float64
end

function Base.show(io::IO, se::SideEffects)
    print(io, "SideEffects(HF=$(se.HF), MC=$(se.MC), AC=$(se.AC))")
end

function SideEffects(S::Set{Set{String}}, HUIs::Dict{Set{String}, Int}, sanitized_HUIs::Dict{Set{String}, Int}, dig::Int = 4)
    H = Set(keys(HUIs))
    sanitized_H = Set(keys(sanitized_HUIs))
    NS = setdiff(H, S)

    SideEffects(hiding_failure(S, H, sanitized_H, dig), missing_cost(NS, sanitized_H, dig), artificial_cost(H, sanitized_H, dig))
end

function hiding_failure(S::Set{Set{String}}, H::Set{Set{String}}, sanitized_H::Set{Set{String}}, dig::Int)
    round(length(intersect(S, sanitized_H)) / length(H), digits=dig)
end

function missing_cost(NS::Set{Set{String}}, sanitized_H::Set{Set{String}}, dig::Int)
    round(length(setdiff(NS, sanitized_H)) / length(NS), digits=dig)
end

function artificial_cost(H::Set{Set{String}}, sanitized_H::Set{Set{String}}, dig::Int)
    round(length(setdiff(sanitized_H, H)) / length(H), digits=dig)
end