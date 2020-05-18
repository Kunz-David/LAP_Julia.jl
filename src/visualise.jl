module visualise

export showflow, imgshowflow, imgshow, warp_imgshowflow, showsparseflow

using PyPlot #: quiver, gcf, figure, imshow, subplots, title, xlabel, ylabel, gca
import LAP_julia: interpolation.warp_img
using LAP_julia
using Printf

# set plot size defaults
SMALL = 8
MEDIUM = 10
LARGE = 12

rc("font", size=SMALL)          # controls default text sizes
rc("axes", titlesize=LARGE)     # fontsize of the axes title
rc("axes", labelsize=SMALL)     # fontsize of the x and y labels
rc("xtick", labelsize=SMALL)    # fontsize of the tick labels
rc("ytick", labelsize=SMALL)    # fontsize of the tick labels
rc("legend", fontsize=SMALL)    # legend fontsize
rc("figure", titlesize=LARGE)   # fontsize of the figure title
rc("figure", figsize=(6,6))
rc("figure", dpi=400)
rc("savefig", dpi=400)
rc("image", origin="lower")
# rcdefaults()

#TODO: join showsparseflow and showflow


"""
    imgshow(img; <keyword arguments>)

Return a figure with image `img`. Plot origin is in the botom left.

# Arguments
- `fig=nothing`: add a figure to plot in. By defaults creates a blank new figure.
- `figtitle::String="Image"`: add title to the figure.
- `ret::Symbol=:figure`: set return object, by default returns Figure, other options: :pyobject returns a PyObject. (Using figure makes Juno directly plot.)


See also: [`showflow`](@ref), [`imgshowflow`](@ref), [`warp_imgshowflow`](@ref)
"""
function imgshow(img; fig=nothing, figtitle::String="Image", ret::Symbol=:figure)

    if fig == nothing
        fig, ax = subplots(dpi = 300)
    else
        fig = fig
        ax = gca()
    end

    img = Float64.(img)

    imshow(img, cmap = :gray);
    # ax.set_ylim(0, size(img)[1]-1);
    # ax.set_xlim(0, size(img)[2]-1);

    title(figtitle)

    if ret == :figure
        return gcf()
    elseif ret == :pyobject
        return ax
    end
end

"""
    showflow(flow::Flow; <keyword arguments>)

Return a figure with the displacement field `flow` by default skipping some vectors to make it easy to read.

# Arguments
- `flow::Flow`: the vector flow to be plotted.
- `skip_count=nothing`: the number of vectors to skip between each displayed vector. By default set so that the output is ``20 × 20`` vectors.
- `fig=nothing`: add a figure to plot in. By defaults creates a blank new figure.
- `mag::Real=1`: magnify the plotted vectors.
- `key::Bool=true`: add key with maximum vector length.
- `figtitle::String="Flow"`: add title to the figure.
- `ret::Symbol=:figure`: set return object, by default returns Figure, other options: :pyobject returns a PyObject. (Using figure makes Juno directly plot.)

See also: [`imgshow`](@ref), [`imgshowflow`](@ref), [`warp_imgshowflow`](@ref)
"""
function showflow(flow::Flow; skip_count=nothing, fig=nothing, mag::Real=1, key::Bool=true, figtitle::String="Flow", ret::Symbol=:figure)

    # set defaults
    if skip_count == nothing
        vecs_in_one_dim = 20
        skip_count = ceil(Int64, maximum(size(flow))/vecs_in_one_dim)-1
    end

    # prepare data
    uv_flow = zeros(size(flow)..., 2)
    uv_flow[:, :, 1] = real(flow)
    uv_flow[:, :, 2] = imag(flow)

    n = skip_count+1

    siz = size(flow)

    # meshgrid(x, y) = (repeat(x, outer=length(y)), repeat(y, inner=length(x)))

    # The x coordinates of the arrow locations
    X = [1:siz[2];]

    # The y coordinates of the arrow locations
    Y = [1:siz[1];]

    trimmed_real = fill(NaN, size(uv_flow[:,:,1]))
    trimmed_real[1:n:end, 1:n:end] .= uv_flow[1:n:end, 1:n:end, 1]
    trimmed_imag = fill(NaN, size(uv_flow[:,:,2]))
    trimmed_imag[1:n:end, 1:n:end] .= uv_flow[1:n:end, 1:n:end, 2]

    maxi = maximum(filter(!isnan, abs.([trimmed_imag trimmed_real])))

    scaling = maxi/(n * mag)
    color = atan.(trimmed_real, trimmed_imag)
    color = (color .- minimum(color)) ./ maximum(color)

    if fig == nothing
        fig, ax = subplots(dpi = 400)
    else
        fig = fig
        ax = gca()
    end

    q = ax.quiver(X, Y, trimmed_real, trimmed_imag, atan.(trimmed_real, trimmed_imag),
            scale_units = "xy", scale = scaling)

    # angles='uv' sets the angle of vector by atan2(u,v), angles='xy' draws the vector from (x,y) to (x+u, y+v)
    ax.set_aspect(1.)
    xlabel("x - real\n\n")
    ylabel("y - imag")
    title(figtitle)

    if key == true
        # subplots_adjust(bottom=0.1)
        label_text = "length = " * @sprintf("%0.2f", maxi)
        ax.quiverkey(q, X=0.75, Y = 0.2, U = maxi, coordinates="inches",
        label=label_text, labelpos = "E")
    end

    if ret == :figure
        return gcf()
    elseif ret == :pyobject
        return q
    end
end

function showsparseflow(flow::Flow; fig=nothing, mag::Real=1, key::Bool=true, figtitle::String="Flow", ret::Symbol=:figure)

    # set defaults
    min_threshold = 1e-10
    vecs_in_one_dim = 20
    skip_count = ceil(Int64, maximum(size(flow))/vecs_in_one_dim)-1
    n = skip_count + 1

    # prepare data
    uv_flow = zeros(size(flow)..., 2)
    uv_flow[:, :, 1] = real(flow)
    uv_flow[:, :, 2] = imag(flow)

    # The x coordinates of the arrow locations
    X = [1:size(flow, 2);]

    # The y coordinates of the arrow locations
    Y = [1:size(flow, 1);]

    cond = ((abs.(real(flow)) .> min_threshold) .| (abs.(imag(flow)) .> min_threshold))

    trimmed_real = fill(NaN, size(uv_flow[:,:,1]))
    trimmed_real[cond] .= uv_flow[:, :, 1][cond]
    trimmed_imag = fill(NaN, size(uv_flow[:,:,2]))
    trimmed_imag[cond] .= uv_flow[:, :, 2][cond]

    maxi = maximum(filter(!isnan, abs.([trimmed_imag trimmed_real])))

    scaling = maxi/(n * mag)

    if fig == nothing
        fig, ax = subplots(dpi = 400)
    else
        fig = fig
        ax = gca()
    end

    q = ax.quiver(X, Y, trimmed_real, trimmed_imag, atan.(trimmed_real, trimmed_imag),
            scale_units = "xy", scale = scaling)

    # angles='uv' sets the angle of vector by atan2(u,v), angles='xy' draws the vector from (x,y) to (x+u, y+v)
    ax.set_aspect(1.)
    xlabel("x - real\n")
    ylabel("y - imag")
    title(figtitle)

    if key == true
        # subplots_adjust(bottom=0.1)
        label_text = "length = " * @sprintf("%0.2f", maxi)
        ax.quiverkey(q, X=0.35, Y = 0.2, U = maxi, coordinates="inches",
        label=label_text, labelpos = "E")
    end

    if ret == :figure
        return gcf()
    elseif ret == :pyobject
        return q
    end
end

"""
    imgshowflow(img, flow; <keyword arguments>)

Return a figure with an image `img` and displacement field `flow`.

# Arguments
- `img`: the image to be plotted.
- `flow::Flow`: the vector flow to be plotted.
- `skip_count=nothing`: the number of vectors to skip between each displayed vector. By default set so that the output is ``20 × 20`` vectors.
- `fig=nothing`: add a figure to plot in. By defaults creates a blank new figure.
- `mag::Real=1`: magnify the plotted vectors.
- `key::Bool=true`: add key with maximum vector length.
- `figtitle::String="Iamge with Flow"`: add title to the figure.
- `ret::Symbol=:figure`: set return object, by default returns Figure, other options: :pyobject returns a PyObject. (Using figure makes Juno directly plot.)

See also: [`imgshow`](@ref), [`showflow`](@ref), [`warp_imgshowflow`](@ref)

"""
function imgshowflow(img, flow::Flow; skip_count=nothing, fig=nothing, mag::Real=1, key::Bool=true, figtitle::String="Image with Flow", ret::Symbol=:figure)
    fig = imgshow(img, fig=fig, figtitle="", ret=:figure)
    showflow(flow, skip_count=skip_count, fig=fig, mag=mag, key=key, figtitle=figtitle, ret=ret);
end

"""
    warp_imgshowflow(img, flow; <keyword arguments>)

Return a figure with an image and a displacement field, where the image is warped by the displacement field.

# Arguments
- `img`: the image to be plotted.
- `flow::Flow`: the vector flow to be plotted.
- `skip_count=nothing`: the number of vectors to skip between each displayed vector. By default set so that the output is ``20 × 20`` vectors.
- `fig=nothing`: add a figure to plot in. By defaults creates a blank new figure.
- `mag::Real=1`: magnify the plotted vectors.
- `key::Bool=true`: add key with maximum vector length.
- `figtitle::String="Iamge with Flow"`: add title to the figure.
- `ret::Symbol=:figure`: set return object, by default returns Figure, other options: :pyobject returns a PyObject. (Using figure makes Juno directly plot.)

See also: [`imgshow`](@ref), [`showflow`](@ref), [`imgshowflow`](@ref)
"""
function warp_imgshowflow(img, flow::Flow; skip_count=nothing, fig=nothing, mag::Real=1, key::Bool=true, figtitle::String="Warped Image with Flow", ret::Symbol=:figure)
    imgw = warp_img(img, -real(flow), -imag(flow))
    imgshowflow(imgw, flow, skip_count=skip_count, fig=fig, mag=mag, key=key, figtitle=figtitle, ret=ret);
end

end #module
