// Shared BIOS 214 interactive Plotly helpers and Reveal.js lifecycle hooks
window.BIOS214 = (() => {
  const C = {
    blue: '#2a7fb8', orange: '#e9782d', green: '#238b59', purple: '#9b58cf',
    yellow: '#c6a400', red: '#db4654', gray: '#89939c', ink: '#343a40'
  };
  const palette = ['#636EFA', '#EF553B', '#00CC96', '#AB63FA', '#19D3F3'];
  const config = {displayModeBar: false, responsive: true};
  const axis = {
    showgrid: true, gridcolor: '#e8ebed', zeroline: true, zerolinecolor: C.gray,
    showline: true, linecolor: C.gray, mirror: true, ticks: 'outside', automargin: true
  };
  const imageAxis = {
    ...axis, showticklabels: false, ticks: '', showgrid: false, zeroline: false
  };
  const baseLayout = (extra = {}) => ({
    font: {size: 20, color: C.ink},
    paper_bgcolor: 'rgba(0,0,0,0)',
    plot_bgcolor: 'rgba(0,0,0,0)',
    margin: {l: 68, r: 30, t: 45, b: 95},
    legend: {orientation: 'h', x: 0.5, xanchor: 'center', y: 1.1},
    ...extra
  });

  function slider(steps, prefix, suffix = '', active = 0, extra = {}) {
    return {
      steps, active, x: 0.05, len: 0.9, y: -0.25, pad: {t: 10},
      ticklen: 0, minorticklen: 0, font: {color: 'rgba(0,0,0,0)'},
      currentvalue: {visible: prefix !== '', prefix, suffix, offset: 8, font: {size: 20, color: C.ink}},
      bordercolor: C.blue, activebgcolor: C.blue, transition: {duration: 0},
      ...extra
    };
  }

  async function standaloneSlider(Plotly, id, values, prefix, label, draw) {
    draw(values[0]);
    const el = document.getElementById(id);
    if (!el) return;
    const hidden = {visible: false, fixedrange: true};
    const half = el.classList.contains('half-slider');
    const showSteps = el.classList.contains('show-steps');
    const steps = values.map((v, i) => ({label: label(v), value: String(i), method: 'skip', args: []}));
    await Plotly.react(el, [{type: 'scatter', x: [null], y: [null]}], {
      xaxis: hidden, yaxis: hidden, margin: {l: 68, r: 68, t: 8, b: 0},
      paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)', showlegend: false,
      sliders: [slider(steps, prefix, '', 0, {
        x: half ? 0.28 : 0.06, len: half ? 0.44 : 0.88, y: 1, pad: {t: 0},
        ticklen: showSteps ? 6 : 0,
        font: {color: showSteps ? C.ink : 'rgba(0,0,0,0)', size: 17}
      })]
    }, config);
    el.on('plotly_sliderchange', e => draw(values[Number(e.step.value)]));
  }

  function arrowMesh(origins, vectors, color, {
    name = '', radius = 0.015, headRadius = 0.045, headLength = 0.12, sides = 10, caps = true
  } = {}) {
    const mesh = {
      type: 'mesh3d', x: [], y: [], z: [], i: [], j: [], k: [], color, name,
      lighting: {ambient: 1, diffuse: 0, specular: 0, fresnel: 0},
      hoverinfo: 'skip', showlegend: !!name
    };
    const vertex = p => {
      const idx = mesh.x.length;
      mesh.x.push(p[0]); mesh.y.push(p[1]); mesh.z.push(p[2]);
      return idx;
    };
    const face = (a, b, c) => { mesh.i.push(a); mesh.j.push(b); mesh.k.push(c); };
    vectors.forEach((v, idx) => {
      const len = Math.hypot(...v);
      if (len < 1e-9) return;
      const o = origins[idx], n = v.map(a => a / len), tip = o.map((p, k) => p + v[k]);
      const c0 = Math.abs(n[2]) < 0.9 ? [-n[1], n[0], 0] : [0, -n[2], n[1]];
      const cn = Math.hypot(...c0), u = c0.map(a => a / cn);
      const w = [n[1]*u[2] - n[2]*u[1], n[2]*u[0] - n[0]*u[2], n[0]*u[1] - n[1]*u[0]];
      const base = tip.map((p, k) => p - Math.min(headLength, len * 0.65) * n[k]);
      const ring = (ctr, r) => Array.from({length: sides}, (_, s) => {
        const a = 2 * Math.PI * s / sides;
        return vertex(ctr.map((p, k) => p + r * (Math.cos(a) * u[k] + Math.sin(a) * w[k])));
      });
      const a = ring(o, radius), b = ring(base, radius), c = ring(base, headRadius);
      const pt = vertex(tip);
      const oc = caps ? vertex(o) : -1, hc = caps ? vertex(base) : -1;
      for (let s = 0; s < sides; s++) {
        const next = (s + 1) % sides;
        face(a[s], a[next], b[next]); face(a[s], b[next], b[s]);
        if (caps) { face(oc, a[next], a[s]); face(hc, c[next], c[s]); }
        face(c[s], c[next], pt);
      }
    });
    return mesh;
  }

  function linkZoom(Plotly, plots) {
    Promise.all(plots).then(panels => {
      let syncing = false;
      panels.forEach(panel => panel.on('plotly_relayout', change => {
        if (syncing || !Object.keys(change).some(k => /^[xy]axis\.(range|autorange)/.test(k))) return;
        const {xaxis, yaxis} = panel._fullLayout;
        const view = {'xaxis.range': xaxis.range.slice(), 'yaxis.range': yaxis.range.slice()};
        syncing = true;
        Promise.all(panels.filter(o => o !== panel).map(o => Plotly.relayout(o, view)))
          .finally(() => { syncing = false; });
      }));
    });
  }

  const slideHooks = new Map();
  const resizeHooks = [];

  function onSlide(id, draw) { slideHooks.set(id, draw); }
  function onResize(fn) { resizeHooks.push(fn); }

  let hooksAttached = false;

  const resizeVisible = slide => {
    if (!slide) return;
    resizeHooks.forEach(fn => fn(slide));
    const doResize = Plotly => {
      if (!Plotly) return;
      window.Plotly = window.Plotly || Plotly;
      slide.querySelectorAll('.js-plotly-plot').forEach(plot => {
        if (plot.clientWidth > 0 && plot.clientHeight > 0) Plotly.Plots.resize(plot);
      });
    };
    if (window.Plotly) doResize(window.Plotly);
    else if (window.komaPlotly) window.komaPlotly.then(doResize);
  };

  const handleSlide = () => {
    const current = window.Reveal?.getCurrentSlide?.();
    if (current && !current.dataset.bios214Drawn) {
      const draw = slideHooks.get(current.id);
      if (draw) {
        current.dataset.bios214Drawn = 'true';
        Promise.resolve(draw()).then(() => resizeVisible(current));
      }
    }
    requestAnimationFrame(() => resizeVisible(current));
  };

  function attachGlobalHooks() {
    if (hooksAttached) return;
    hooksAttached = true;
    // Release stuck Plotly slider drags when mouseup happens outside the plot
    let draggingPlot = null;
    document.addEventListener('mousedown', e => {
      draggingPlot = e.target.closest?.('.slider-container') ? e.target.closest('.js-plotly-plot') : null;
    }, true);
    const release = () => {
      if (!draggingPlot) return;
      const p = draggingPlot; draggingPlot = null;
      p.dispatchEvent(new MouseEvent('mouseup', {bubbles: false, buttons: 0}));
    };
    window.addEventListener('mouseup', release, true);
    window.addEventListener('blur', release);
    window.addEventListener('mousemove', e => { if (e.buttons === 0) release(); }, true);

    if (window.Reveal) {
      Reveal.on('slidechanged', handleSlide);
      Reveal.on('slidetransitionend', handleSlide);
      Reveal.on('ready', handleSlide);
    }
    window.addEventListener('resize', () => resizeVisible(window.Reveal?.getCurrentSlide?.()));
    handleSlide();
  }

  function onReady(fn) {
    window.addEventListener('load', async () => {
      const Plotly = window.komaPlotly ? await window.komaPlotly : window.Plotly;
      if (Plotly && !window.Plotly) window.Plotly = Plotly;
      await fn(Plotly);
      attachGlobalHooks();
      handleSlide();
    });
  }

  window.addEventListener('load', attachGlobalHooks);

  return {C, palette, config, axis, imageAxis, baseLayout, slider, standaloneSlider, arrowMesh, linkZoom, onSlide, onResize, onReady};
})();
