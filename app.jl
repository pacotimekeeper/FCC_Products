#setup of the Genie Framework environment
module App

using Main.Config

using GenieFramework
using JSON
using JLD2
using DataFrames

!ispath(joinpath(APP_PATH, "data")) && mkpath(joinpath(APP_PATH, "data"))

route("/jsonpayload/:fileName", method = POST) do
# route("/jsonpayload/mappings", method = POST) do
    println("AM in post route")
    try
        fileName = params(:fileName, "NO PARAMS")

        print("Working on Json Payload for $(fileName)...")
        jsonPayload = Genie.Requests.jsonpayload()
        println("completed")
    
        print("Saving JLD2 for $(fileName).jld2...")
        filePath = joinpath(APP_PATH, "data", "$(fileName).jld2")
        save_object(filePath, DataFrame(jsonPayload))
        print("Done!")
        
        respond("It works", :text)
    catch e
        println(e)
        respond("try again", :text)
    end
end

include("pages/ChcsjPubp.jl")
# include("pages/Dummy.jl")
end

# [compat]
# GenieFramework = "2"
