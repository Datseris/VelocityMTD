#=
Power-law slope plot for the paper.
=#
using DrWatson
@quickactivate "VelocityMTD"
using MusicManipulations, PyPlot, Statistics, PyCall
include(srcdir("extract_data.jl"))
include(srcdir("PSD.jl"))
include(srcdir("style.jl"))
include(srcdir("vel_normalization.jl"))

pushfirst!(PyVector(pyimport("sys")."path"), srcdir())
pypsd = pyimport("PSD")
pyimport("importlib")."reload"(pypsd)

fig, axs = subplots(1,3,figsize = (2figx, figx/2))
axtap, axu, axp = axs

# %% Plot PSD of tapping
axtap.clear()
tapping_no = 3
p = datadir("exp_raw", "tapping")
axtap.set_title("tapping", color = "C1")

midi = readMIDIFile(joinpath(p, readdir(p)[tapping_no]))
notes = getnotes(midi)

psdfit!(axtap, notes; minsub = 1)
axtap.set_ylabel("PSD")

# %% PG music
axu.clear()
pg_no = 5
minsub = 12
mindur, tpq = 960÷minsub, 960
axu.set_title("PG music", color = "C3")

p = datadir("exp_raw", "pgmusic")
midi = readMIDIFile(joinpath(p, readdir(p)[pg_no]))
notes = getnotes(midi)

psdfit!(axu, notes, 2)


# %% Plot PSD of playalong
axp.clear()
playalong_no = 1
minsub = 12

axp.set_title("playalongs", color = "C4")

p = datadir("exp_raw", "playalongs")
midi = readMIDIFile(joinpath(p, readdir(p)[playalong_no]))
notes = Drums.getnotes_td50(midi, 2)
notes = drums_cleanup(notes)
channeled = channel_direct(notes)
anotes = align_notes(channeled; thres = 3)
notes = combine(anotes)

slope1, slope2 = psdfit!(axp, notes, 2; minsub = minsub)

# %%
fig.tight_layout()
add_identifiers!(fig)
fig.savefig(plotsdir("PSD", "powerlaws"))
