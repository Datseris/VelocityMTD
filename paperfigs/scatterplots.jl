#=
characteristic scatterplots for the paper
=#
using DrWatson
quickactivate(@__DIR__, "VelocityMTD")
using MusicManipulations, PyPlot, StatsBase, Statistics, Parameters
include(srcdir("extract_data.jl"))
include(srcdir("style.jl"))

fig, axs = subplots(1,4,figsize = (2figx, figx/2))

datasets = ["tapping", "uwe", "pgmusic", "playalongs", "playalongs"]
datanames = ["tapping",  "Uwe Meile (piano)", "PG music (piano)", "drums playalongs", "drums playalongs (lead)"]
subsets = ["all", "melody", "melody", "all", "lead"]
datano = [1,1,1,8,8]

for i in 1:5
    # i == 3 && continue
    ax = axs[min(i, 4)]
    dataset = datasets[i]
    subset = subsets[i]
    c = @dict dataset subset
    mtds, vels = get_dataset(c)
    m, v = mtds[datano[i]], vels[datano[i]]
    ax.plot(m, v, ls = "None", color = "C$i", marker = "o", alpha = 0.5)
    if i ≤ 4
        ax.text(0.5, 1.05, datanames[i], va="center", ha="center",
        transform =ax.transAxes, color = "C$i", size = 32)
    else
        ax.text(0.2, 0.9, subsets[i], va="center", ha="center",
        transform =ax.transAxes, color = "C$i", size = 32)
    end
end

axs[1].set_ylabel("velocity", size = 32)
axs[4].set_ylim(0, 140)
# i ∈ (2, 4) && ax.set_xlabel("MTD")
add_identifiers!(fig)
fig.text(0.5, 0.05, "MTD", transform = fig.transFigure, size = 32)
fig.tight_layout()
fig.subplots_adjust(bottom=0.2,wspace = 0.22, hspace = 0.2, top = 0.9)
# fig.savefig(papersdir("figs", "scatterplots"))
