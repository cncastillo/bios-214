using Base64, SHA

function preview_asset(data, suffix, assets)
    name = bytes2hex(sha256(data)) * suffix
    path = joinpath(assets, name)
    isfile(path) || write(path, data)
    name
end

function preview_data_assets(text, assets, prefix="")
    replace(text, r"data:([^;,]+);base64,[A-Za-z0-9+/=]+" => url -> begin
        metadata, payload = split(url, ','; limit=2)
        mime = split(metadata[6:end], ';')[1]
        suffix = get(Dict("font/woff" => ".woff", "font/ttf" => ".ttf",
            "application/vnd.ms-fontobject" => ".eot", "image/svg+xml" => ".svg"), mime, ".bin")
        prefix * preview_asset(base64decode(payload), suffix, assets)
    end)
end

function write_lecture_preview(html, path, assets)
    mkpath(assets)
    head = match(r"<head>(.*?)</head>"s, html)[1]
    styles = map(collect(eachmatch(r"<style\b[^>]*>(.*?)</style>|<link\b[^>]*href=\"data:text/css([^,]*),([^\"]+)\"[^>]*>"s, head))) do style
        css = if style[1] !== nothing
            style[1]
        elseif occursin(";base64", style[2])
            String(base64decode(style[3]))
        else
            replace(style[3], r"%[0-9A-Fa-f]{2}" => code -> String(UInt8[parse(UInt8, code[2:3]; base=16)]))
        end
        name = preview_asset(preview_data_assets(css, assets), ".css", assets)
        "<link rel=\"stylesheet\" href=\"../preview-assets/$name\">"
    end
    title = match(r"<section id=\"title-slide\"[^>]*>.*?</section>"s, html).match
    logo = match(r"<img[^>]*class=\"slide-logo\"[^>]*>", html).match
    footer = match(r"<div class=\"footer[^\"]*\">.*?</div>"s, html).match
    core = match(r"<script[^>]*>\s*(/\*!\s*\*\s*reveal\.js\b.*?)</script>"s, html)[1]
    script = preview_asset(core, ".js", assets)
    config = split(html, "Reveal.initialize({"; limit=2)[2]
    options = join((match(Regex("(?m)^\\s*" * key * ":\\s*[^,\\n]+"), config).match
        for key in ["width", "height", "margin", "center", "rtl"]), ",")
    write(path, """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      $(match(r"<title>.*?</title>"s, head).match)
      $(join(styles, "\n"))
    </head>
    $(match(r"<body[^>]*>", html).match)
      <div class="reveal has-logo">
        <div class="slides">$title</div>
        $(preview_data_assets(logo, assets, "../preview-assets/"))
        $footer
      </div>
      <script src="../preview-assets/$script"></script>
      <script>Reveal.initialize({$options, controls:false, progress:false, keyboard:false, touch:false, hash:false});</script>
    </body>
    </html>
    """)
end

if abspath(PROGRAM_FILE) == @__FILE__
    output = get(ENV, "QUARTO_PROJECT_OUTPUT_DIR", joinpath(dirname(@__DIR__), "_site", "lecture"))
    for folder in readdir(output; join=true)
        html = joinpath(folder, "slides$(basename(folder)).html")
        isfile(html) || continue
        cp(html, joinpath(folder, "index.html"); force=true)
        write_lecture_preview(read(html, String), joinpath(folder, "preview.html"), joinpath(output, "preview-assets"))
    end
end
