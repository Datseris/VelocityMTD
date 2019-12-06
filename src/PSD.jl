using DrWatson
@quickactivate "VelocityMTD"

using PyCall

pushfirst!(PyVector(pyimport("sys")."path"), srcdir())
pypsd = pyimport("PSD")
pyimport("importlib")."reload"(pypsd)

"""
Plot the PSD and its fit on `ax`. Input is velocity timeseries (or the notes
to calculate the timeseries from, by averaging velocity).

`kwargs` are propagated into `Python.psd`, while `minsub, tpq` are
"""
function psdfit!(ax, notes::Notes, middle = nothing;
    minsub = 12, tpq = 960, kwargs...)

    t, v = timeseries(notes, :velocity, mean, 0:(1//minsub):1)
    v = [ismissing(vi) ? 0 : vi for vi in v]
    psdfit!(ax, v, middle; minsub = minsub, tpq = tpq, kwargs...)
end

function psdfit!(ax, v::Vector, middle = nothing;
    minsub = 12, tpq = 960, kwargs...)

    mindur = tpq÷minsub

    f2b = (f) -> @. mindur/f/tpq
    b2f = (b) -> @. mindur/b/tpq

    f, psd = pypsd.psd(v; kwargs...)
    lo, up, N = pypsd.chisquare_ci(get(kwargs, :overlap_factor, 20) - 1)

    beats = f2b.(f[2:end])

    ax.loglog(beats, psd[2:end], c= "C0", lw = 1.5, basex=2)
    ax.fill_between(beats, psd[2:end] .* up ./ N, psd[2:end] .* lo ./ N, color = "C0", alpha = 0.25)

    if isnothing(middle)
        fs1, sl1, slope1 = pypsd.fit_powerlaw(f, psd, mindur, tpq; upper = maximum(beats), lower = minimum(beats))
        ax.plot(f2b.(fs1), sl1, label = "\$\\beta\$ = $(round(slope1; digits=2))", c = "C5")
        slope2 = 0.0
    else
        fs1, sl1, slope1 = pypsd.fit_powerlaw(f, psd, mindur, tpq; upper = middle, lower = minimum(beats))
        fs2, sl2, slope2 = pypsd.fit_powerlaw(f, psd, mindur, tpq; upper = maximum(beats), lower = middle)
        ax.plot(f2b.(fs1), sl1, label = "\$\\delta\$ = $(round(slope1; digits=2))", c = "C2")
        ax.plot(f2b.(fs2), sl2, label = "\$\\beta\$ = $(round(slope2; digits=2))", c = "C5")
    end

    ax.legend()
    ax.set_xlabel("period (beats)")
    ax.grid()
    return slope1, slope2
end
