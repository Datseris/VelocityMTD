#=
Power-law slope plot for the paper.
=#
using DrWatson
@quickactivate "VelocityMTD"
using MusicManipulations, PyPlot, Statistics
include(srcdir("style.jl"))

datasets = ["tapping", "uwe", "pgmusic", "playalongs"]
datanames = ["tapping",  "Uwe Meile (piano)", "PG music (piano)", "drums playalongs"]

fig = figure(figsize = (2figx, 3figx/4))
axβ = subplot(311)
axδ = subplot(312)
axb = subplot(313)
axs = (axβ, axδ, axb)

alldata = load(datadir("psd", "alldatasets.bson"))

# %% plot
pcount = 0
for ax in axs; ax.clear(); end

for i in 1:length(datasets)
    dataset = datasets[i]
    data = alldata[dataset]

    βs = data[:βs]
    δs = data[:δs]
    bs = data[:bs]

    L = length(bs)
    l = pcount + 1
    r = l + L - 1

    for (j, (ax, q)) in enumerate(zip(axs, (βs, δs, bs)))
        ax.plot(l:r, q, color = "C$(i)", ls = "None", marker = "o")
        j != 3 && ax.plot([l, r], fill(mean(q), 2), color = "C$(i)", lw = 2, alpha = 0.75)
    end

    axb.text((r+l)/2, 3.5, datanames[i], ha="center", va="center", color = "C$i")

    global pcount += L+1
    # break
end

for ax in axs; ax.set_xlim(0, 54); end
for ax in axs[1:2]; ax.set_xticklabels([]); end

axβ.set_ylabel("\$\\beta\$")
axβ.set_yticks(-1.2:0.4:0.2)
axβ.set_ylim(-1.2, 0.2)
axβ.axhline(0, zorder = - 99)
axβ.invert_yaxis()
axβ.yaxis.grid(true)
# axβ.axhline(0, color = "black", ls = "dashed", lw = .5)
# axβ.axhline(-1, color = "black", ls = "dashed", lw = .5)

axδ.set_ylabel("\$\\delta\$")
axδ.set_yticks(0:0.4:1.2)
axδ.axhline(0, zorder = - 99)

axδ.set_ylim(-0.2, 1.2)
axδ.yaxis.grid(true)
# axδ.axhline(0, color = "black", ls = "dashed", lw = .5)
# axδ.axhline(1, color = "black", ls = "dashed", lw = .5)

axb.set_ylabel("\$b_c\$")
axb.set_yticks(1:4)
axb.set_xlabel("recording #")

add_identifiers!(fig; loc = (0.995, 0.975))
fig.align_ylabels()
fig.tight_layout()
fig.subplots_adjust(hspace = 0.2)
# fig.savefig(plotsdir("psd", "allpsd"))
