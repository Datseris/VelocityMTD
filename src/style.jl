#=
Styling file for the figures of the velocity correlation paper.
=#
using PyPlot
PyPlot.rc("lines", lw = 2.6)

PyPlot.rc("font", size = 26) # set default fontsize
PyPlot.rc("axes", labelsize = 32)
PyPlot.rc("legend", fontsize = 26)

PyPlot.rc("xtick.major", size = 10)
PyPlot.rc("xtick.minor", size = 6)

# PyPlot.rc("font", family = "Times New Roman") # Serif main font
PyPlot.rc("font", family = "DejaVu Sans") # sans main font
# PyPlot.rc("mathtext", rm = "sanserif", fontset="dejavusans") # sans math font
PyPlot.rc("mathtext", rm = "serif", fontset="cm") # serif math font

const figx = 12
# default figsize (full span, 2-3 rows)
PyPlot.rc("figure", figsize = (2figx, figx))
PyPlot.rc("savefig", dpi = 300, transparent = true, format = "pdf")

mutable struct CyclicContainer
    c::Vector
    n::Int
end
CyclicContainer(c) = CyclicContainer(c, 0)

Base.length(c::CyclicContainer) = length(c.c)
Base.iterate(c::CyclicContainer, state=1) = Base.iterate(c.c, state)
Base.getindex(c::CyclicContainer, i) = c.c[(i-1)%length(c.c) + 1]
function Base.getindex(c::CyclicContainer)
    c.n += 1
    c[c.n]
end
COLORS = CyclicContainer(
["#233B43", "#499cbf", "#E84646",
 "#168e6c","#C29365", "#985CC9",
 "#822e01", "#7c6d8c"])
MARKERS = CyclicContainer(["o", "s", "^", "p", "P", "D", "X"])
LINES = CyclicContainer([ ":", "-", "--", "-."])
# Also set default color cycle
PyPlot.rc("axes", prop_cycle = matplotlib.cycler(color=COLORS.c))
PyPlot.rc("lines", markersize = 10)

_bbox(α) = Dict(:boxstyle => "round,pad=0.3", :facecolor=>"white", :alpha => α)

bbox = Dict(:boxstyle => "round,pad=0.3", :facecolor=>"white", :alpha => 1.0)

function add_identifiers!(fig = gcf(); loc = (0.985, 0.975))
    bbox = Dict(:boxstyle => "round,pad=0.3", :facecolor=>"white", :alpha => 1.0)
    for (i, ax) in enumerate(fig.get_axes())
        l = collect('a':'z')[i]
        try
            ax.text(loc..., "$(l)",
            transform = ax.transAxes, bbox = bbox, zorder = 99)
        catch err
            ax.text(loc..., 1, "$(l)",
            transform = ax.transAxes, bbox = bbox, zorder = 99)
        end
    end
end
function coolhist!(ax, data, bins, color, label = "", alpha = 0.25)
    h, b, = ax.hist(data, bins, density = true, color = color,
    alpha = alpha)

    b = 0.5(b[1:end-1] .+ b[2:end])
    ax.plot(b, h, color = color, lw = 1.0, label = label)
end
