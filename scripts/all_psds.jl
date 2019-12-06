#=
Power-law slope plot for the paper.
=#
using DrWatson
@quickactivate "VelocityMTD"
using MusicManipulations, PyPlot, Statistics
include(srcdir("style.jl"))
include(srcdir("drums_processing.jl"))
include(srcdir("vel_normalization.jl"))
include(srcdir("PSD.jl"))

# %% ############# Tapping #######################
files = readdir(datadir("exp_raw", "tapping"))
# constants
middles = fill(NaN, length(files))
βs = zeros(length(files))
δs = fill(NaN, length(files))

close("all")

for (i, file) in enumerate(files)
    midi = readMIDIFile(datadir("exp_raw", "tapping", file))
    notes = getnotes(midi)
    @show length(notes)
    middle = middles[i]
    minsub = 1

    figure(figsize = (10,10))
    ax = gca()
    slope1, slope2 = psdfit!(ax, notes, nothing; minsub = minsub, tpq = midi.tpq)
    βs[i] = slope1
    ax.set_title("$(file[1:end-4])_sub=$(minsub)")
    tight_layout()
    savefig(plotsdir("psd", "tapping", file*".png"))
end

bs = middles

tapping = @dict βs δs bs



# %% ############# PLAYALONGS #######################
allnotes = aligned_drums_notes()

# %%
files = readdir(datadir("exp_raw", "playalongs"))
# middles: must be optimized
middles = fill(2.0, length(allnotes))
middles[2] = 4
middles[3] = 4
middles[9] = 3

βs = zeros(length(files))
δs = zeros(length(files))

close("all")

for (i, notes) in enumerate(allnotes)
    notes = combine(notes)
    @show length(notes)

    middle = middles[i]
    file = files[i][1:end-4]
    minsub = 12
    figure(figsize = (10,10))
    ax = gca()
    slope1, slope2 = psdfit!(ax, notes, middle; minsub = minsub)
    # β is large time scales!
    βs[i] = slope2
    δs[i] = slope1
    ax.set_title("playalong_$(file)_middle=$(middle)")
    tight_layout()
    savefig(plotsdir("psd", "playalongs", file*".png"))
end

bs = middles

playalongs = @dict βs δs bs

# %% ############## UWE #######################
files = readdir(datadir("exp_raw", "uwe"))
# constants
middles = fill(2.0, length(files))
middles[2] = 3
middles[3] = 1.5
middles[4] = 3

βs = zeros(length(files))
δs = zeros(length(files))

close("all")

for (i, file) in enumerate(files)

    midi = readMIDIFile(joinpath(datadir("exp_raw", "uwe"), file))
    piano = getnotes(midi, 2)
    d = estimate_delay(piano, 0:1//3:1)
    notes = translate(piano, -round(Int, d))
    @show length(notes)

    middle = middles[i]
    minsub = 6

    figure(figsize = (10,10))
    ax = gca()
    # notice the different window factor and overlap used for the Uwe dataset
    # (because it has smaller amount of points)
    slope1, slope2 = psdfit!(ax, notes, middle; minsub = minsub,
    window_factor = 2, overlap_factor = 4)
    βs[i] = slope2
    δs[i] = slope1
    ax.set_title("$(file[1:end-4])_sub=$(minsub)")
    tight_layout()
    savefig(plotsdir("psd", "uwe", file*".png"))
end

bs = middles

uwe = @dict βs δs bs


# %% ############## PG Music #######################
files = readdir(datadir("exp_raw", "pgmusic"))
# constants
middles = fill(2.0, length(files))
middles[1] = 1.5
middles[15] = 3
middles[17] = 4
βs = zeros(length(files))
δs = zeros(length(files))

close("all")

for (i, file) in enumerate(files)
    midi = readMIDIFile(datadir("exp_raw", "pgmusic", file))
    notes = getnotes(midi)
    @show length(notes)
    middle = middles[i]
    minsub = 12

    figure(figsize = (10,10))
    ax = gca()
    slope1, slope2 = psdfit!(ax, notes, middle; minsub = minsub, tpq = midi.tpq)
    βs[i] = slope2
    δs[i] = slope1
    ax.set_title("$(file[1:end-4])_sub=$(minsub)")
    tight_layout()
    savefig(plotsdir("psd", "pgmusic", file*".png"))
end

bs = middles

pgmusic = @dict βs δs bs

# %% Save data:
@tagsave(datadir("psd", "alldatasets.bson"), @strdict uwe pgmusic playalongs tapping)
