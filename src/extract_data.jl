#=
This file defines functions that simply return all timeseries of velocity
and timing from the different sources we have. E.g. PG13, Uwe recordings,
Drum playalongs, drum tapping, etc.
Any extra options (like e.g. using only melody, etc.), are passed
as keyword arguments.

All functions always return (mtds, vels)
=#
include("drums_processing.jl")

function uwe_data(;subset = "all")
    uwedir = datadir("exp_raw", "uwe")
    mtds = []
    vels = []
    for file in readdir(uwedir)
        midi = readMIDIFile(joinpath(uwedir, file))
        piano = getnotes(midi, 2)
        d = estimate_delay(piano, 0:1//3:1)
        piano = translate(piano, -round(Int, d))

        asr, σasr = Jazz.average_swing_ratio(piano, "swung8s")

        x = asr/(asr + 1)
        grid = [0, x/2, x, 1]

        if subset == "all"
            qnotes = quantize(piano, grid)
            class = classify(piano, grid)
            # in the following do not use notes in the x/2 bin; outliers
            a = findall(!isequal(2), class)

            m = positions(piano)[a] .- positions(quantize(piano, grid))[a]
            v = velocities(piano)[a]
        elseif subset == "melody"
            # only highest pitch notes
            fvel(notes) = ((m, i) = findmax(pitches(notes)); notes[i].velocity)
            fpos(notes) = ((m, i) = findmax(pitches(notes)); notes[i].position)
            t, v = timeseries(piano, fvel, grid)

            tt, p = timeseries(piano, fpos, grid)
            nomiss = @. !ismissing.(v)

            m = @. round(Int, p[nomiss] .- tt[nomiss])
            v = @. round(Int, v[nomiss])
        end
        push!(vels, v); push!(mtds, m)
    end
    return mtds, vels
end

function playalongs_data(; subset = "all")
    pdir = datadir("exp_raw", "playalongs")
    mtds = []
    vels = []
    for file in readdir(pdir)
        grid = file[3] == 'j' ? (0:1//3:1) : (0:1//4:1)
        midi = readMIDIFile(joinpath(pdir, file))
        drums = Drums.getnotes_td50(midi.tracks[2], midi.tpq)
        drums = drums_cleanup(drums)

        d = estimate_delay_recursive(drums, grid, 5)
        drums = translate(drums, -d)

        if subset == "all"
            drums = drums
        elseif subset == "lead"
            drums = filterpitches(drums, [0x1a, 0x2e, 0x35, 0x33])
        elseif subset == "snare"
            drums = filterpitches(drums, [0x26, 0x28])
        elseif subset == "kick"
            drums = filterpitches(drums, [0x24])
        elseif subset == "quarters"
            class = classify(drums, grid)
            keep = [c ∈ (1, length(grid)) ? true : false for c in class]
            drums = drums[keep]
        elseif subset == "aligned"
            channeled = channel_direct(drums)
            aligned = align_notes(channeled)
            drums = combine(aligned)
        end
        drums = remove_peaking_velocities!(drums)
        qnotes = quantize(drums, grid)
        m = positions(drums) .- positions(qnotes)
        v = velocities(drums)
        length(v) == 0 && continue
        push!(vels, v); push!(mtds, m)
    end
    return mtds, vels
end

function tapping_data(;subset = "all")
    cordir = datadir("exp_raw", "tapping")
    mtds = []
    vels = []
    for file in readdir(cordir)
        midi = readMIDIFile(joinpath(cordir, file))
        hits = getnotes(midi)
        grid = 0:1
        d = round(Int, mean(relpos(hits, grid)))
        hits = translate(hits, -d)
        drum_q = quantize(hits, 0:1)
        mtd = positions(hits) .- positions(drum_q)
        vel = velocities(hits)
        push!(mtds,mtd)
        push!(vels,vel)
    end
    return mtds, vels
end

function find_first(notes)
  tmp, first_notes = Notes(), Notes()
  for (index,qn) in enumerate(quantize(notes,0:1)[1:end-1])
    push!(tmp, notes[index])
    if quantize(notes,0:1)[index+1].position != qn.position
      push!(first_notes, tmp[findmax(pitches(tmp))[2]])
      tmp = Notes()
    end
  end
  return first_notes
end

"""
    pgmusic_data(bool, interval) → mtd, vels

extracts the MTDs and velocities for all the pieces in the pgmusic datadir.

  input :
    - first : boolean argument that determines if we take the whole chords into account or just the top notes that corresponds to the melody line
    - interval : the interval into which we consider a note to be a quarter note. Since the recordings are complex, it is hqrd to find q single grid that describes everything for quantization.
      so every notes which is in [960 - lower_limit, upper_limit] ticks is considered a quarter note.
  returns :
    - mtd : a vector of vector containing the MTDs for each piece.
    - vel : a vector of vector containing the vels for each piece.
"""
function pgmusic_data(;subset = "all")
    if subset == "all"
        first = false
    elseif subset == "melody"
        first = true
    end
    boundary = [-100,125]

    pgdir = datadir("exp_raw","pgmusic")
    MTDs, vels = [], []
    for file in readdir(pgdir)
        notes = getnotes(readMIDIFile(joinpath(pgdir, file)),1)
        tmp, quarter_notes = Notes(), Notes()
        lower_limit, upper_limit = boundary[1], boundary[2]
        #Taking all the notes in the interval - limit: limit
        for n in notes
            if mod(n.position,960) >= 960 + lower_limit || mod(n.position,960) < upper_limit
                push!(tmp,n)
            end
        end
        if first
            quarter_notes = find_first(tmp)
        elseif first == false
            quarter_notes = tmp
        end
        # moduloing the positions, and substracting tpq when applicable to get mtdS
        # can't use '''quantize''' since we don't have a clear grid.
        pos = mod.(positions(quarter_notes),960)
        for i in 1:length(pos)
            if pos[i] >= 960 + lower_limit
            pos[i] -= 960
            end
        end
        push!(MTDs, pos)
        push!(vels, velocities(quarter_notes))
    end
    return MTDs, vels
end

"""
    find_top_notes(notes)
finds the top notes (gets rid of chords, keeps melody) on a grid [0:1//6:1].
"""
function find_top_notes(notes)
  tmp, first_notes = Notes(), Notes()
  for (index,qn) in enumerate(quantize(notes,collect(0:1//6:1))[1:end-1])
    push!(tmp, notes[index])
    if quantize(notes,collect(0:1//6:1))[index+1].position != qn.position
      push!(first_notes, tmp[findmax(pitches(tmp))[2]])
      tmp = Notes()
    end
  end
  return first_notes
end


function get_dataset(c::Dict)
    dataset = c[:dataset]
    subset = get(c, :subset, "all")
    get_dataset(dataset, subset)
end
function get_dataset(dataset, subset = "all")
    if dataset == "uwe"
        mtds, vels = uwe_data(;subset=subset)
    elseif dataset == "playalongs"
        mtds, vels = playalongs_data(;subset=subset)
    elseif dataset == "tapping"
        mtds, vels = tapping_data(;subset=subset)
    elseif dataset == "pgmusic"
        mtds, vels = pgmusic_data(;subset=subset)
    end
    return mtds, vels
end

get_dataset_names(c::Dict) = get_dataset_names(c[:dataset])
function get_dataset_names(dataset::String)
    dir = datadir("exp_raw", dataset)
    return [f[1:end-4] for f in readdir(dir)]
end
