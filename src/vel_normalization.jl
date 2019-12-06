#=
Contains functions for processing velocity histograms, smoothing them,
aligning them, and more.
Takes advantage of the Integer nature of velocity!
=#
using DSP, Statistics, MusicManipulations

##############################
# Histograms
##############################
"""
    velhist(notes::Notes)

Get a histogram of the velocity.
"""
function velhist(notes::Notes{N}) where N
    mv = maximum(n.velocity for n in notes) + 50 # some buffer
    h = zeros(Int, mv+1)
    for n in notes
        h[n.velocity+1] += 1
    end
    return h
end

function velhist(v::Vector{<:Real})
    h = zeros(Int, maximum(v)+1)
    for vi in v
        h[vi+1] += 1
    end
    return h
end

"""
    velhists(notes)
Get a dictionary of velocity histograms,
each for a specific pitch of the `notes`.
(can also accept a dictionary directly)
"""
function velhists(notes::Notes)
    sep = separatepitches(notes)
    velhists(sep)
end
function velhists(sep::Dict)
    histos = Dict{UInt8, Vector{Float64}}()
    for k in keys(sep)
        histos[k] = velhist(sep[k])
    end
    return histos
end



"""
    smoothhist(h, w = PEAKW)

Smoothen out a histogram via convolution with Gaussian of window size `w`.
"""
smoothhist(notes::Notes, w = PEAKW) = smoothhist(velhist(notes), w)
function smoothhist(hist::AbstractVector, w = PEAKW)
    #prepare
    normal1 = maximum(hist)
    gaußk = exp.(-range(-0.3, 0.3, length = w).^2)

    #smoothen
    histc = DSP.conv(hist,gaußk)
    histc = DSP.conv(histc,gaußk)
    histc = DSP.conv(histc,gaußk)
    histc = DSP.conv(histc,gaußk)

    #normalize, cut and clean
    normal2 = maximum(histc)
    histc = histc./(normal2/normal1)
    histc = histc[(2w-1):end-(2w-2)]
    for i = 1:length(histc)
        if histc[i] ≤ 1
            histc[i] = 0
        end
    end
    return histc
end

"good value for peak detection & alignment"
const PEAKW = 7

smoothhists(s::Dict{K, <: Notes}) where {K} = smoothhists!(velhists(s))
function smoothhists!(vhists::Dict, w = PEAKW)
    for k in keys(vhists)
        vhists[k] = smoothhist(vhists[k], w)
    end
    return vhists
end

##############################
# Velocity peaks
##############################
"""
    find_peaks(h, thres = 2)
Find the peak indices of the given (expected smooth) histogram `h`.
Only consider peaks that have at least `thres` height.
"""
function find_peaks(h, thres = 2)
    peaks = findall(i -> h[i-1] < h[i] > h[i+1], 2:length(h)-1)
    del = findall(i -> h[i] < thres, peaks)
    deleteat!(peaks, del)
    return peaks .+ 1 # because the search range starts from 2
end


"""
    aling_peaks(notes; thres = 2, w = PEAKW, method = :scale)
Separate the `notes` by pitch, and then for each pitch calculate the
velocity histogram. Align these histograms based on the peak of
highest velocity (the "forte" peak), and return the aligned histograms
as a dictionary `pitch => histogram`.

The `method` indicates whether the `:scale` the histograms or `:shift` them
to match.
"""
function aling_peaks(notes; w = PEAKW, thres = 2, method = :scale)
    sepa = align_notes(notes; w = w, thres = thres, method = method)
    vhists = velhists(sepa)
    return vhists
end

function align_notes(notes; w = PEAKW, thres = 2, method = :scale)
    sepa = separatepitches(notes)
    vhists = velhists(sepa)
    smoothhists!(vhists, w)
    allpeaks = Dict((k, find_peaks(vhists[k], thres)) for k in keys(vhists))
    center = maximum(maximum(p) for (k, p) in allpeaks if length(p) != 0)
    # modify the velocity for each notes
    for (k, n) in sepa
        length(allpeaks[k]) == 0 && continue
        forte = maximum(allpeaks[k])
        align!(n, center, forte, method)
    end
    return sepa
end

function align!(notes::Notes, center, forte, method)
    center == forte && return

    for i in 1:length(notes)
        n = notes[i]
        if method == :shift
            n.velocity += center - forte
        elseif method == :scale
            n.velocity = round(Int, n.velocity * (center/forte))
        end
    end
    return
end


#######################
# Aligned drum notes
#######################
"""
    aligned_drums_notes()
Return a vector of all the drum playalong notes processed in the following way:
1. Fake hihat notes are removed.
2. Remove drum notes that we decide to not analyze due to their nature.
3. Shift time of drums to 0 of grid.
4. Channel notes into the 5 main channels (Lennart's thesis).
5. Align the forte peaks of each channel.
"""
function aligned_drums_notes()
    playdir = datadir("exp_raw", "playalongs")
    fdir = readdir(playdir)
    total = []
    for (i, file) in enumerate(fdir)
        midi = readMIDIFile(joinpath(playdir, file))
        notes = Drums.getnotes_td50(midi, 2)
        notes = drums_cleanup(notes)
        channeled = channel_direct(notes)
        anotes = align_notes(channeled; thres = 3)
        # all good but for some files we need manual adjustments
        if i == 3
            for n in anotes[2] # snare
                v = n.velocity
                n.velocity = v > 45 ? v - 45 : 0
            end
        end
        push!(total, anotes)
    end
    return total
end
