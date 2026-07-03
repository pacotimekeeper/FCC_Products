import Pkg
Pkg.activate(".")

using GenieFramework
Genie.loadapp()

up(8080, "0.0.0.0", async = true)
# using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json



