#=
Cross-correlation plot for the paper.
Depending on the `absolute` variable, compare velocity with MTD or with
abs(MTD).

Integrates with DrWatson to not re-produce the data. Change `force` to
true to re-calculate correlations.
=#
using DrWatson
quickactivate(@__DIR__, "VelocityMTD")
using MusicManipulations, PyPlot, StatsBase, Statistics, Parameters
include(srcdir("correlations.jl"))
include(srcdir("extract_data.jl"))
include(srcdir("style.jl"))

datasets = ["tapping", "uwe", "pgmusic", "playalongs", "playalongs"]
datanames = ["tapping",  "Uwe Meile (piano)", "PG music (piano)", "drums playalongs", "drums playal. (lead)"]
subsets = ["all", "melody", "melody", "all", "lead"]
absolute = true

pcount = 0
fig = figure(figsize = (2figx, 3figx/4))
axρ = subplot(311)
axm = subplot(312)
axmn = subplot(313)
xlocs = zeros(length(datasets))
total = zeros(Int, length(datasets))
significant = zeros(Int, length(datasets))


for i in 1:length(datasets)
    # i == 3 && continue
    dataset = datasets[i]
    subset = subsets[i]
    c = @dict dataset subset absolute

    file, = produce_or_load(
        datadir("crosscor"), c, correlation_intervals;
        prefix = "crosscor",
        force = false
    )

    @unpack ρs, ρus, ρds, MIs, centers, MIus, MIds = file

    L = length(ρs)
    l = pcount + 1
    r = l + L - 1

    axρ.errorbar(l:r, ρs, yerr = hcat(ρus,ρds)',
    ecolor = "C0", color = "C$(i)", ls = "None", marker = "o")

    bot = mean(ρs) - mean(ρds)
    top = mean(ρs) + mean(ρus)
    rec = matplotlib.patches.Rectangle((l, bot), r-l, top-bot, color = "C$(i)",
    alpha = 0.2)
    # axρ.add_patch(rec)

    axρ.plot([l, r], [mean(ρs), mean(ρs)], color = "C$(i)", lw = 2, alpha = 0.75)


    # Plot default MI
    axm.plot([l, r], fill(mean(MIs),2), color = "C$(i)",
    lw = 2, alpha = 0.75)

    axm.errorbar(l:r, centers, yerr = hcat(MIus,MIds)',
    ecolor = "C0", color = "C0", ls = "None")
    axm.plot(l:r, MIs,  color = "C$(i)", ls = "None",
    marker = "o")
    y = 0.1
    # axm.axhline(0, color = "black", ls = "dashed", lw = 1.0)
    axm.set_ylim(0, 0.9)

    # plot normalized MI
    # make normalized mi
    no = zeros(length(MIs))
    for i in 1:length(no)
        mic = MIs[i] - centers[i]
        no[i] = if mic < 0
            mic/(MIds[i])
        else
            mic/(MIus[i])
        end
        no[i] = abs(no[i])
    end
    # plot it
    axmn.plot(l:r, no,  color = "C$(i)", ls = "None",
    marker = "o")
    # average
    axmn.plot([l, r], fill(mean(no), 2), color = "C$(i)",
    lw = 2, alpha = 0.75)
    axmn.axhline(1, color = "black", ls = "dashed", lw = 0.5)
    y = 3
    axmn.set_ylim(0, 4)

    axmn.text((r+l)/2, y, datanames[i], ha="center", va="center", color = "C$i")

    global pcount += L+1
    total[i] = length(no)
    significant[i] = count(n -> n > 1, no)
end

axρ.axhline(0, color = "black", ls = "dashed", lw = .5)
axρ.set_xticklabels([])
axρ.set_yticks(-0.3:0.2:0.3)
axρ.set_ylabel("\$\\rho\$")
axρ.set_title("correlation between velocity and $(absolute ? "abs(MTD)" : "MTD")")

axm.set_yticks(0:0.2:0.8)
axm.set_xticklabels([])
axm.set_ylabel("MI")

axmn.set_yticks(0:4)
axmn.set_ylabel("MI (norm.)")
axmn.set_xlabel("recording #")

#
for ax in fig.axes
    ax.minorticks_on()
    ax.tick_params(axis="y", which="minor", left=false)
    ax.set_xlim(0, pcount)
    ax.tick_params(axis="x", width =2, length=10)
    ax.tick_params(axis="x", which="minor", width = 1.5, length = 8)
end
add_identifiers!(fig; loc = (0.995, 0.975))
fig.align_ylabels()
fig.tight_layout()
fig.subplots_adjust(hspace = 0.2)
# fig.savefig(papersdir("figs", "crosscorrelations"))
fig.savefig(plotsdir("crosscorrelations", "absolute=$(absolute)"))
