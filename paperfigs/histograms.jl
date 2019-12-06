#=
Histogram plot for the paper.
left subplot: histograms of tapping, uwe, PGmusic
right: histogram of 1 playalong, with colors denoting instruments
=#

using DrWatson
quickactivate(@__DIR__, "VelocityMTD")
using MusicManipulations, PyPlot, StatsBase, Statistics
include(srcdir("extract_data.jl"))
include(srcdir("vel_normalization.jl"))
include(srcdir("style.jl"))

# Get velocities/drumnotes
datano = [1,1,1,7]
mtds, velstap = tapping_data()
tapping = velstap[datano[1]]
mtds, velsuwe = uwe_data(; subset="melody")
uwe = velsuwe[datano[2]]
mtds, velspg = pgmusic_data(;subset="melody")
pgmusic = velspg[datano[3]]

datanames = ["tapping",  "Uwe Meile", "PG music", "drums playalongs"]

# drums notes
drums = begin
    pdir = datadir("exp_raw", "playalongs")
    file = readdir(pdir)[datano[4]]
    grid = file[3] == 'j' ? (0:1//3:1) : (0:1//4:1)
    midi = readMIDIFile(joinpath(pdir, file))
    drums = Drums.getnotes_td50(midi.tracks[2], midi.tpq)
    drums = drums_cleanup(drums)
    d = estimate_delay_recursive(drums, grid, 5)
    drums = translate(drums, -d)
end

fig = figure(figsize = (2figx, 2figx/3))
axp = subplot(121)
axd = subplot(122)
fig.tight_layout()

# %% plot smoothened piano histograms
axp.clear()
for (i, v) in enumerate((tapping, uwe, pgmusic))
    sh = smoothhist(velhist(v), 3)
    sh ./= sum(sh)
    x = 0:length(sh)-1
    axp.plot(x, sh, color = "C$(i)", label = datanames[i])
    axp.fill_between(x, sh, color = "C$(i)",
    alpha=0.25)
end
axp.legend()
axp.set_yticks([])
axp.set_ylabel("normalized density")
axp.set_xlabel("velocity")

# %%
axd.clear()
channeled = channel_direct(drums)
sepa = separatepitches(channeled)

for (key, val) in sepa
    key == INVALID && continue
    sh = smoothhist(val, 3)
    x = 0:length(sh)-1
    axd.plot(x, sh, color = "C$(key-1)", label = CHANNELNAMES[key])
    axd.fill_between(x, sh, color = "C$(key-1)",
    alpha=0.25)
end
axd.set_yticks([])
axd.set_xlim(0, 150)
axd.legend()
axd.set_ylabel("density")
axd.set_xlabel("velocity")

# %% final adjust
fig.tight_layout()
add_identifiers!(fig)
# fig.savefig(papersdir("figs", "histograms"))
