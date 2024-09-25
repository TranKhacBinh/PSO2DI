include("./Dataset.jl")
include("./HUIM/Utility.jl")
include("./HUIM/Algorithm/D2HUP.jl")
#include("./HUIM/Algorithm/HUI_Miner.jl")

#include("./PPUM/Algorithm/Evolutionary/PSO2DI.jl")
include("./PPUM/Algorithm/Evolutionary/PPUMGAT.jl")
include("./PPUM/Algorithm/Evolutionary/PSO2DI_v1.jl")
include("./PPUM/SideEffects.jl")








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

utilTable = Dict("A" => 9, "B" => 11, "C" => 4, "D" => 6, "E" => 7)

HUIs = Dict(
	Set(["A", "C", "D", "E"]) => 205,
	Set(["B", "C", "D", "E"]) => 274,
	Set(["B", "C"]) => 223,
    Set(["A", "C", "D"]) => 234,
	Set(["B", "C", "E"]) => 226,
	Set(["C", "D", "E"]) => 266,
    Set(["B", "E"]) => 202,
	Set(["B", "D"]) => 289,
	Set(["C", "E"]) => 305,
    Set(["B", "D", "E"]) => 250,
	Set(["B", "C", "D"]) => 325,
	Set(["C", "D"]) => 278
)

huis_miner = hui_miner(transactions, utilTable, 200)
Dict((pair -> Set(pair[1]) => pair[2]).(collect(huis_miner))) == HUIs
=#
