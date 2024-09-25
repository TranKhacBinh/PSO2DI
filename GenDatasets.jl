include("./Dataset.jl")
include("./UtilityGenerator.jl")

dataset_names = ["chess", "foodmart", "mushrooms", "t25i10d10k"]
int_util_ranges = [1:10, 1:10, 1:10, 1:10]
ext_util_range = [1:1000, 1:1000, 1:1000, 1:1000]

for (i, dataset_name) in enumerate(dataset_names)
    transaction = load_transactions("./TransactionsDB/$(dataset_name).txt")
    dataset = gen_dataset(dataset_name, transaction, int_util_ranges[i], ext_util_range[i])
    save(dataset)
    clone_dataset = load_dataset(dataset_name)
    println(dataset == clone_dataset)
end