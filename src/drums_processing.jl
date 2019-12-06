#=
Base code for processing the drums dataset.
=#
#######################
# Channeling
#######################
#map pitches to destination channels (INVALID for discarding)
const INVALID = 9
const TOCHANNEL = Dict{UInt8,UInt8}(
    0x24=>1, #"Kick",
    0x26=>2, #"Snare",
    0x28=>2, #"Snare Rimshot",
    0x1a=>3, #"Hihat Rim",
    0x2e=>3, #"Hihat Head",
    0x33=>4, #"Ride Head",
    0x35=>4, #"Ride Bell",
    0x27=>5, #Tom 4 Rimshot,
    0x29=>5, #Tom 4,
    0x2b=>5, #"Tom 3",
    0x2d=>5, #"Tom 2",
    0x2f=>5, #"Tom 2 Rimshot",
    0x30=>5, #"Tom 1",
    0x32=>5, #"Tom 1 Rimshot",
    0x3a=>5, #"Tom 3 Rimshot",
    0x25=>INVALID, #"Snare RimClick",
    0x2c=>INVALID, #"Hihat Foot Close",
    0x31=>INVALID, #"Cymbal 1",
    0x3b=>INVALID, #"Ride Rim",
    0x37=>INVALID, #"Cymbal 1",
    0x39=>INVALID, #"Cymbal 2",
    0x34=>INVALID, #"Cymbal 2",
    0x2a=>INVALID,
    0x16=>INVALID,
)

const NOTANALYZABLE = [x for x in keys(TOCHANNEL) if TOCHANNEL[x] == INVALID]

const CHANNELNAMES = Dict{UInt8,String}(
    1=>"Kick",
    2=>"Snare",
    3=>"Hihat",
    4=>"Ride",
    5=>"Toms",
    6=>"All in one",
    INVALID=>"Not analyzable"
)


function channel_direct!(notes::Notes, map = TOCHANNEL)
    for note in notes
        note.pitch = map[note.pitch]
    end
    return notes
end

"""
    channel_direct(notes::Notes, map = TOCHANNEL)
Channel `notes` into the mapping specified by `map`
(by changing their pitch).
"""
channel_direct(notes, map = TOCHANNEL) = channel_direct!(copy(notes), map)

#######################
# Cleanup
#######################
function drums_cleanup(drums;
    back = 200, forw = 200, cutoff_fc = 30, cutoff_vel = 20)

    Drums.rm_hihatfake!(drums;
    back = back, forw = forw, cutoff_fc = cutoff_fc, cutoff_vel = cutoff_vel,
    cut_pitches=[0x2e])

    remove = NOTANALYZABLE
    drums = removepitches(drums, remove)
    return drums
end

function remove_peaking_velocities!(drums)
    digital = Drums.DIGITAL
    peak(v) = v ∈ digital ? 159 : 127
    remove = Int[]
    for i in 1:length(drums)
        note = drums[i]
        if note.velocity ≥ peak(note.velocity)
            push!(remove, i)
        end
    end
    deleteat!(drums.notes, remove)
    return drums
end
