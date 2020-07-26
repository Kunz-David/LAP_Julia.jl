
# # Registration Functions Showcase
#
#md # [![](https://mybinder.org/badge_logo.svg)](@__BINDER_ROOT_URL__/generated/example_placeholder.ipynb)
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/generated/example_placeholder.ipynb)

# In this example page I will show how to work with the registration algorithms [`lap`](@ref), [`pflap`](@ref), [`sparse_lap`](@ref) and [`sparse_pflap`](@ref).

# I will generate some images to show the workings and function calls.

## using the package
using LAP_julia;

## default arguments:
img, imgw, flow = gen_init();

# See the [`Basic Interaction`](@ref basic_interaction) section or the [`Public Documentation`](@ref public_api) for more advanced input generation

# __These are the differences between the `target` (`img`) and `source` (`imgw`) images.__

# ## Full LAP Methods

# These functions are from the algorithms from the paper [Local All-Pass Geometric Deformations](https://www.researchgate.net/publication/320574179_Local_All-Pass_Geometric_Deformations).

# ### [`lap`](@ref) function

## set a filter half size, which is larger than the default max displacement: 10 used in gen_init
fhs = 15;
flow_est, source_reg = lap(img, imgw, fhs);

# This gives us a estimation of the flow and the registered source image

# This is what the registered source image looks

# ### [`pflap`](@ref) function

flow_est, source_reg = pflap(img, imgw);

# This gives us a estimation of the flow and the registered source image
