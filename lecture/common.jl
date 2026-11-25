# Shared Julia plotting, Quarto display, and MRI simulation helpers for BIOS 214 lectures

using KomaMRI
using KomaMRI.KomaMRIPlots.PlotlyBase

const BIOS_COLORS = (
    blue   = "#2a7fb8",
    orange = "#e9782d",
    green  = "#238b59",
    purple = "#9b58cf",
    yellow = "#c6a400",
    red    = "#db4654",
    gray   = "#89939c",
    ink    = "#343a40",
    palette = ["#636EFA", "#EF553B", "#00CC96", "#AB63FA", "#19D3F3"],
)

rows(a) = [collect(row) for row in eachrow(a)]

# ---- Direct Quarto PlotlyBase.Plot rendering using Koma's offline Plotly.js (loaded once) ----

const _KOMA_PLOTLY_EMITTED = Ref(false)
_KOMA_PLOTLY_EMITTED[] = false

function _koma_plotly_loader_script()
    src = replace(read(KomaMRI.KomaMRIPlots.TIME_PLOTLY.local_path, String), "</script" => "<\\/script")
    """<script>
    (function() {
      if (!window.Plotly) {
        var _amd = window.define && window.define.amd;
        if (_amd) window.define.amd = false;
        try {
    $src
        } finally {
          if (_amd) window.define.amd = _amd;
        }
      }
      window.komaPlotly = Promise.resolve(window.Plotly);
    })();
    </script>"""
end

function plotly_loader_html()
    _KOMA_PLOTLY_EMITTED[] && return Base.HTML("")
    _KOMA_PLOTLY_EMITTED[] = true
    Base.HTML(_koma_plotly_loader_script())
end

embed_json(id, data) = Base.HTML(
    "<script id=\"$id\" type=\"application/json\">" * PlotlyBase.JSON.json(data) * "</script>"
)

struct _Bios214Loader end
Base.show(io::IO, ::MIME"text/html", ::_Bios214Loader) = print(io, _koma_plotly_loader_script())

struct _Bios214Plot
    plot::PlotlyBase.Plot
end

function Base.show(io::IO, ::MIME"text/html", wrapper::_Bios214Plot)
    p = wrapper.plot
    html = sprint(buf -> PlotlyBase.to_html(
        buf, p;
        autoplay = false,
        include_plotlyjs = "require-loaded",
        include_mathjax = missing,
        full_html = false,
    ))
    html = replace(html,
        "require([\"plotly\"], function(Plotly) {" =>
        "window.komaPlotly.then(function(Plotly) { window.Plotly = window.Plotly || Plotly;";
        count = 1,
    )
    html = replace(html, r"((?:height|width):\s*\d+);" => s"\1px;")
    print(io, html)
end

if isdefined(Main, :QuartoNotebookWorker)
    function Main.QuartoNotebookWorker.expand(p::PlotlyBase.Plot)
        plot_cell = Main.QuartoNotebookWorker.Cell(_Bios214Plot(p))
        if !_KOMA_PLOTLY_EMITTED[]
            _KOMA_PLOTLY_EMITTED[] = true
            return [Main.QuartoNotebookWorker.Cell(_Bios214Loader()), plot_cell]
        end
        return [plot_cell]
    end
end

# ---- Shared PlotlyBase styling helpers ----

bios_config(; kwargs...) = PlotConfig(;
    displayModeBar = false, displaylogo = false, responsive = true, kwargs...
)

bios_plot(traces, layout::Layout; config=bios_config()) = Plot(traces, layout; config)
bios_plot(traces; config=bios_config(), kwargs...) = Plot(traces, bios_layout(; kwargs...); config)

# PlotlyBase automatically sets transpose=true on heatmaps assuming a column-major Matrix;
# when given row-major Vector{Vector} (e.g. from rows(M)), disable transpose to prevent 90° rotation.
bios_heatmap(z; kwargs...) = heatmap(; z, transpose=!(z isa AbstractVector), kwargs...)

bios_axis(; kwargs...) = attr(;
    showgrid = true, gridcolor = "#e8ebed",
    zeroline = true, zerolinecolor = BIOS_COLORS.gray,
    showline = true, linecolor = BIOS_COLORS.gray,
    mirror = true, ticks = "outside", automargin = true,
    kwargs...
)

bios_image_axis(; kwargs...) = attr(;
    showgrid = false, zeroline = false,
    showline = true, linecolor = BIOS_COLORS.gray, mirror = true,
    showticklabels = false, ticks = "", automargin = true,
    kwargs...
)

bios_layout(; font_size=20, kwargs...) = Layout(;
    font = attr(size=font_size, color=BIOS_COLORS.ink),
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor = "rgba(0,0,0,0)",
    margin = attr(l=68, r=30, t=40, b=75),
    legend = attr(orientation="h", x=0.5, xanchor="center", y=1.1),
    kwargs...
)

bios_slider(steps, prefix; suffix="", active=0, x=0.05, len=0.9, y=-0.25, pad_t=10, offset=10, kwargs...) = attr(;
    steps, active, x, len, y, pad=attr(t=pad_t),
    ticklen=0, minorticklen=0, font=attr(color="rgba(0,0,0,0)"),
    currentvalue=attr(visible=(prefix != ""), prefix=prefix, suffix=suffix,
        offset=offset, font=attr(size=20, color=BIOS_COLORS.ink)),
    bordercolor=BIOS_COLORS.blue, activebgcolor=BIOS_COLORS.blue,
    transition=attr(duration=0),
    kwargs...
)

function clean_seq_plot(seq; height=nothing, width=nothing, font_size=17, margin=nothing, kwargs...)
    p = plot_seq(seq; slider=false, show_rf_frame=false, kwargs...)
    for trace in p.data
        get(trace, :name, "") == "|B1|_AM" && (trace.name = "B₁")
        get(trace, :visible, true) == "legendonly" && (trace.showlegend = false)
    end
    isnothing(height) || (p.layout.height = height)
    isnothing(width)  || (p.layout.width = width)
    p.layout.font = attr(size=font_size, color=BIOS_COLORS.ink)
    p.layout.paper_bgcolor = "rgba(0,0,0,0)"
    p.layout.plot_bgcolor = "rgba(0,0,0,0)"
    isnothing(margin) || (p.layout.margin = margin)
    p.config = bios_config()
    p
end

# ---- Shared KomaMRI simulation helpers ----

function record_states(obj, seq, sys; Δt=1e-3, Δt_rf=10e-6, shown=nothing,
        record_net=false, max_block_length=1, max_rf_block_length=1)
    n = length(obj.x)
    idx = isnothing(shown) ? collect(1:n) : shown
    times = [0.0]
    states = [hcat(zeros(length(idx)), zeros(length(idx)), ones(length(idx)))]
    net = record_net ? [[0.0, 0.0, 1.0]] : Vector{Vector{Float64}}()
    record = function (progress, blocks, data, _)
        push!(times, data.seqd.t[last(blocks.parts[progress.block])])
        push!(states, hcat(real.(data.Xt.xy[idx]), imag.(data.Xt.xy[idx]), copy(data.Xt.z[idx])))
        if record_net
            push!(net, [real(sum(data.Xt.xy)), imag(sum(data.Xt.xy)), sum(data.Xt.z)] ./ n)
        end
    end
    simulate(obj, seq, sys; verbose=false, callbacks=(record,),
        sim_params=Dict{String,Any}(
            "gpu"=>false, "Nthreads"=>1, "precision"=>"f64",
            "Δt"=>Δt, "Δt_rf"=>Δt_rf,
            "max_block_length"=>max_block_length,
            "max_rf_block_length"=>max_rf_block_length,
            "return_type"=>"state",
        ))
    (; times, states, net)
end

function load_brain_96x96()
    raw = read(joinpath(@__DIR__, "4", "figures", "brain-density-96x96.raw"))
    reverse(permutedims(reshape(Float64.(raw) ./ 255, 96, 96)); dims=1)
end

function cartesian_line(ky, sys; excitation, nx=96, fov=0.24, dwell=5e-6, pre_pad=0.25e-3, tr=nothing)
    step = 1 / fov
    flat = (nx - 1) * dwell
    readout = PulseDesigner.make_trapezoid(; flat_area=(nx - 1) * step, flat_time=flat, sys)
    pre_area = -nx / 2 * step - γ * readout.A * readout.rise / 2
    pre_x = PulseDesigner.make_trapezoid(; area=pre_area, sys)
    pre_y = PulseDesigner.make_trapezoid(; area=ky, sys)
    enc_dur = max(dur(pre_x), dur(pre_y)) + pre_pad
    seq = isnothing(excitation) ? Sequence(sys) : deepcopy(excitation)
    addblock!(seq;
        x = PulseDesigner.make_trapezoid(; area=pre_area, duration=enc_dur, sys),
        y = PulseDesigner.make_trapezoid(; area=ky, duration=enc_dur, sys))
    addblock!(seq, ADC(nx, flat, readout.rise); x=readout)
    isnothing(tr) || addblock!(seq, Delay(tr - dur(seq)))
    seq
end
