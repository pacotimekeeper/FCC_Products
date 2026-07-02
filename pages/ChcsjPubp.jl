module ChcsjPubp

using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

# 1. Define your standard Julia struct
# mutable struct User
#     name::String
#     age::Int
# end
function processDf()
    mapping = load_object("mappings.jld2")
    # mapping = DataFrame(XLSX.readtable("_all_mappings.xlsx"))
    mapping = filter("CHCSJ_PUBP(Y/N)" => x-> !ismissing(x) && x =="Y", mapping)
    cols = [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description]
    for col in cols
        mapping[!, col] .= coalesce.(mapping[!, col], "missing")
        mapping[!, col] .= string.(mapping[!, col])
    end
    # dropmissing!(mapping, :CHCSJ_Product_Description)
    unique!(mapping, :CHCSJ_Modelo)
    select!(mapping, cols)
    sort(mapping, [:Supplier, :用途, :CHCSJ_Product_Description], rev = false)
end

function getData(df)
    return [OrderedDict(pairs(row)) for row in eachrow(df)]
end

function filterData(searchText, suppliers)
    tdf = processDf()
    text = lowercase(searchText)
    tdf = filter(:Supplier => in(suppliers), tdf)
    return tdf[
        (contains.(lowercase.(tdf.用途), text)) .| 
        (contains.(tdf.CHCSJ_物品編號, text)) .| 
        (contains.(lowercase.(tdf.CHCSJ_Product_Description), text)), :]
    # filter([:col1, :col2] => ((x, y) ->  contains(x, text) || contains(y, text)), tdf)
    # return filter([:CHCSJ_物品編號, :CHCSJ_Product_Description] => ((x, y) ->  contains(lowercase(x), text) || contains(lowercase(y), text)), tdf)
end

const df = processDf()

@app begin
    @out suppliers = unique(df.Supplier)
    @in selectedSuppliers = unique(df.Supplier)
    # @in process = false
    
    # @out sdf = df
    @in searchText = ""
    @in btnSearchText = false
    @out theads = names(df)
    @out trows = getData(df)
    
    @onchange selectedSuppliers begin
        tdf = filterData(searchText, selectedSuppliers)
        trows = getData(tdf)
    end

    @onbutton btnSearchText begin
        tdf = filterData(searchText, selectedSuppliers)
        trows = getData(tdf)
    end

end

@page("/", "views/chcsj_pubp_items.jl.html")
# @page("/chcsj_pubp_items", "chcsj_pubp_items.jl.html")

end