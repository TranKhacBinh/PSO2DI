include("./Dataset.jl")
include("./HUIM/Utility.jl")
include("./HUIM/Algorithm/D2HUP.jl")
include("./HUIM/Algorithm/HUI_Miner.jl")

dataset_names = ["chess", "foodmart", "mushrooms", "t25i10d10k"]

dataset = load_dataset(dataset_names[4])
println(dataset)

#dataset.mut[] = 0.2
min_util = ceil(Int, (dataset.total_util[] * dataset.mut[]) / 100)
#dataset.huis[] = d2hup(dataset.transactions, dataset.utilTable, min_util)
println("End")
dataset.huis[]
#save(dataset)

all(utility(itemset, dataset.transactions, dataset.utilTable) == util for (itemset, util) in pairs(dataset.huis[]))