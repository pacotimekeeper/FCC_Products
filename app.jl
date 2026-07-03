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
        println("AM in post route")
        
        jsonPayload = Genie.Requests.jsonpayload()
        println("jsonpaylod work")
    
        filePath = joinpath(APP_PATH, "data", "$(fileName).jld2")
        println("file Path is found $filePath")
    
        save_object(filePath, DataFrame(jsonPayload))
        println("object is saved")
        
        respond("It works", :text)
    catch e
        println(e)
        respond("try again", :text)
    end
end

include("pages/ChcsjPubp.jl")
include("pages/Dummy.jl")
end

# [compat]
# GenieFramework = "2"
