#=
Definition of measures of cross-correlation and power-law correlation
=#
using MIDI, MusicManipulations
using Statistics, Random
using InformationMeasures
using DCCA

"""
    mutualinformation(x, y [, N]) → MI, MICI, center

Compute MI and it's confidence interval w.r.t the null hypothesis
(i.e no correlations), via bootstrap procedure (total of `N` times),
between `x` and `y`.

The confidence interval for the mutual information corresponding to
the null-hypothesis of no correlations. If the value of MI lies outside this
interval, then `x` and `y` are co-dependant.

Return MI, it's confidence interval and the center of the interval's distribution.
"""
function mutualinformation(MTD::Vector, vel::Vector, N = 10000)
    MTD = copy(MTD); vel = copy(vel)
    MI = round(get_mutual_information(MTD,vel), digits = 2)
    # direct estimation of error bars for MI is too complex.
    # test the null-hypothesis instead.
    # bootstraping procedure to get 95% confidence interval for MI under null-hypothesis.
    bootstrap = zeros(N)
    for i in 1:N
        bootstrap[i] = get_mutual_information(shuffle!(MTD), shuffle!(vel))
    end
    sort!(bootstrap)
    MiCI = (bootstrap[max(N÷40, 1)], bootstrap[N - N÷40])
    center = bootstrap[N÷2]
    return MI, MiCI, center
end

function normalized_mi(MTD::Vector, vel::Vector, N = 10000)
    mi, mici, cen = mutualinformation(MTD, vel, N)
    normalized_mi(mi, mici, cen)
end
function normalized_mi(mi::Real, mici::Tuple, cen::Real)
    mic = mi-cen
    if mic < 0
        return mic/(cen - mici[1])
    else
        return mic/(mici[2] - cen)
    end
end


"""
    pearson(x, y) → ρ, CI
Compute ρ, and it's 95% confidence interval between `x` and `y`.

Notice that `CI` is a 2-tuple (for low and upper bounds).
"""
function pearson(MTD::Vector,vel::Vector)
    r = cor(MTD,vel)
    #computing z transform and standard deviation for r'S error bars.
    #going to the z_transform space makes the distribution symmetric
    z_transform = 0.5*log((1+r)/(1-r))
    sigma = sqrt(1/(length(vel)-3))
    z_critical = 1.96*sigma
    #going back to the r space.
    rCI = (tanh(z_transform - z_critical), tanh(z_transform + z_critical))
    return r, rCI
end

"""
    bin_array(x, bin_size) → binned_array
Bin 'x' with a bin width of 'bin_size'.
"""
function bin_array(x::Array{Int,1}, bin_size::Int)
    new_bins = collect(unique(sort(x))[1]:bin_size:unique(sort(x))[end])
    binned_array = Int[]
    for value in x
        for index in 1:length(new_bins)-1
            if value >= new_bins[index] && value < new_bins[index+1]
                push!(binned_array,new_bins[index])
            end
            if value >= new_bins[end]
                push!(binned_array, new_bins[end])
                break
            end
        end
    end
    return binned_array
end


"""
    correlation_intervals(c)
Given container `c`, integrate with DrWatson's `produce_or_load` and
make a file that contains the Pearson and MI data.
"""
function correlation_intervals(c)
    mtds, vels = get_dataset(c)

    if get(c, :absolute, false)
        for i in 1:length(mtds)
            mtds[i] = abs.(mtds[i])
        end
    end

    # Pearson
    ρs = Float64[]
    ρus = Float64[]
    ρds = Float64[]
    # Mutual information stuff
    MIs = Float64[]
    centers = Float64[]
    MIus = Float64[]
    MIds = Float64[]

    for (m, v) in zip(mtds, vels)
        ρ, (d, u) = pearson(m, v)
        push!(ρs, ρ); push!(ρus, u - ρ); push!(ρds, ρ - d)

        MI, MICI, center = mutualinformation(m, v, 10000)
        push!(MIs, MI)
        push!(MIds, center - MICI[1])
        push!(MIus, MICI[2] - center)
        push!(centers, center)
    end
    return @dict( ρs, ρus, ρds, MIs, centers, MIus, MIds )
end


"""
    get_DCCA(x,y,start,stop,pts)
compute the rho_DCCA coefficients for the given window sizes, as well as a c
onfidence interval for the null hypothesis. Return two tuples :
- (points::Vector, values::Vector) which is the results of the DCCA analyses
  for the different time-scales contained in windows
- (l::Float64, u::Float64) the lower and upper bound for the 95% confidence
  interval
"""
function get_DCCA(x::Array{Float64,1},y::Array{Float64,1})
    windows, values = rhoDCCA(x,y)
    l, u = rhoDCCA_CI(x,y)
    return (windows, values), (l,u)
end
