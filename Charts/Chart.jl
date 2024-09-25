include("../Performance.jl")

using Plots
using StatsPlots

function chart(x_value::Vector{Float64}, y_values::Dict{String, Vector{Float64}}, labels::Vector{String}, 
              colors::Vector{Symbol}, markers::Vector{Symbol}, title::String, xlabel::String, ylabel::String)

    p = plot(title=title, xlabel=xlabel, ylabel=ylabel, #yscale=:log10, 
            legend=false) #, titlefont=font(10), guidefont=font(8), tickfont=font(6))
    
    for (i, label) in enumerate(labels)
        plot!(p, x_value, y_values[label], label=label, color=colors[i], 
             marker=markers[i], markersize=4, linewidth=2)
    end
    
    return p
end

function metrics_chart(metrics_name::String, ds_names::Vector{String}, muts::Vector{Vector{Float64}}, sip::Vector{Float64}, 
                      alg_names::Vector{String}, colors::Vector{Symbol}, markers::Vector{Symbol},
                      layout::Tuple{Int, Int}, size::Tuple{Int, Int}, path::String)

    ylabel = Dict("runtime" => "Running Time (sec.)", "HF" => "Hiding Failure (%)", "MC" => "Missing Cost (%)")
    plots = []
    for (i, ds_name) in enumerate(ds_names)
        perf = load_performance(ds_name)
        metrics = get(perf, muts[i], sip[i], metrics_name)

        if metrics_name in ["HF", "MC"]
            metrics = Dict(key => value .* 100 for (key, value) in pairs(metrics))
        end

        p = chart(muts[i], metrics, alg_names, colors, markers, 
                 "$(ds_name) (SIP: $(sip[i])%)", "Minimum Utility Threshold (%)", ylabel[metrics_name])

        push!(plots, p)
    end
    
    legend_plot = plot(; frame=:none, showaxis=false, xticks=nothing, yticks=nothing)
    for (i, alg_name) in enumerate(alg_names)
        plot!(legend_plot, [0], [0], label=alg_name, color=colors[i], marker=markers[i],
             markersize=4, linewidth=2, legend=:bottom) #, legendfontsize=8)
    end

    final_plot = plot(plots..., legend_plot, layout=@layout([grid(layout[1], layout[2]); a{0.15h}]),
                     size=size) #, link=:y) #, plot_title="", plot_titlefont=font(14))

    # Lưu plot
    savefig(final_plot, path)
end

function metrics_chart(metrics_name::String, ds_names::Vector{String}, mut::Vector{Float64}, sips::Vector{Vector{Float64}}, 
                      alg_names::Vector{String}, colors::Vector{Symbol}, markers::Vector{Symbol},
                      layout::Tuple{Int, Int}, size::Tuple{Int, Int}, path::String)

    
    ylabel = Dict("runtime" => "Running Time (sec.)", "HF" => "Hiding Failure (%)", "MC" => "Missing Cost (%)")
    plots = []
    for (i, ds_name) in enumerate(ds_names)
        perf = load_performance(ds_name)
        metrics = get(perf, mut[i], sips[i], metrics_name)

        if metrics_name in ["HF", "MC"]
            metrics = Dict(key => value .* 100 for (key, value) in pairs(metrics))
        end

        p = chart(sips[i], metrics, alg_names, colors, markers, 
                 "$(ds_name) (MUT: $(mut[i])%)", "Sensitive Information Percentage (%)", ylabel[metrics_name])

        push!(plots, p)
    end

    legend_plot = plot(; frame=:none, showaxis=false, xticks=nothing, yticks=nothing)
    for (i, alg_name) in enumerate(alg_names)
        plot!(legend_plot, [0], [0], label=alg_name, color=colors[i], marker=markers[i],
             markersize=4, linewidth=2, legend=:bottom) #, legendfontsize=8)
    end

    final_plot = plot(plots..., legend_plot, layout=@layout([grid(layout[1], layout[2]); a{0.15h}])
                     ,size=size) #, link=:y) #, plot_title="", plot_titlefont=font(14))

    # Lưu plot
    savefig(final_plot, path)
end



ds_names = ["foodmart", "t25i10d10k"]
alg_names = ["ppumgat", "PSO2DI_v1"]
markers = [:circle, :square]
colors = [:blue, :red]

#=
muts = [[0.05, 0.06, 0.07, 0.08, 0.09], [0.29, 0.30, 0.31, 0.32, 0.33]]
sip = [1.5, 1.2]

metrics_chart("runtime", ds_names, muts, sip, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/runtime1.png")
metrics_chart("HF", ds_names, muts, sip, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/HF1.png")
metrics_chart("MC", ds_names, muts, sip, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/MC1.png")
=#


mut = [0.07, 0.3]
sips = [[2.0, 4.0, 6.0, 8.0, 10.0], [0.6, 0.7, 0.8, 0.9, 1.0]]
metrics_chart("runtime", ds_names, mut, sips, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/runtime2.png")
metrics_chart("HF", ds_names, mut, sips, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/HF2.png")
metrics_chart("MC", ds_names, mut, sips, alg_names, colors, markers, (1, 2), (800, 400), "./Charts/MC2.png")