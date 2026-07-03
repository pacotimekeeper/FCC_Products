module ChcsjPubp
using Main.Config
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
    mapping = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
    mapping = filter(["SAP_Code" , "CHCSJ_PUBP(Y/N)"] => ((x, y) -> x!="missing" && y=="Y"), mapping)
    # mapping = filter("CHCSJ_PUBP(Y/N)" => x-> !ismissing(x) && x =="Y", mapping)
    cols = [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description]
    # for col in cols
    #     mapping[!, col] .= coalesce.(mapping[!, col], "missing")
    #     mapping[!, col] .= string.(mapping[!, col])
    # end
    # # dropmissing!(mapping, :CHCSJ_Product_Description)
    unique!(mapping, :CHCSJ_Modelo)
    select!(mapping, cols)
    sort(mapping, [:Supplier, :用途, :CHCSJ_Product_Description], rev = false)
end

function getData(data)
    return [OrderedDict(pairs(row)) for row in eachrow(data)]
end

# function filterData(searchText, suppliers)
function filterByText(searchText, suppliers)
    tdf = processDf()
    text = lowercase(searchText)
    tdf = filter(:Supplier => in(suppliers), tdf)
    tdf.joinedCol = lowercase.(string.(tdf.CHCSJ_Product_Description, tdf.CHCSJ_物品編號, tdf.用途))
    return tdf[contains.(tdf.joinedCol, text), Not(:joinedCol)]
end

# function filterBySupplier(suppliers)
# end
const headers = [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description]
const df = processDf()

@app begin
    @out suppliers = unique(df.Supplier)
    @in selectedSuppliers = unique(df.Supplier)
    @out tmpSuppliers = unique(df.Supplier)
    
    # @out ddf = df
    @in searchText = ""
    @in btnSearchText = false
    @out theads = headers
    @out trows = getData(df)
    
    @onchange selectedSuppliers begin
        println("selectSupplier", selectedSuppliers)
        println("tmpSuppliers", tmpSuppliers)
        println("searchText",searchText)
        # ddf = filterBySupplier(selectedSuppliers)
        # ddf = filterByText(searchText, ddf)
        # trows = getData(tdf)
    end

    @onbutton btnSearchText begin
        tdf = filterByText(searchText, selectedSuppliers)
        tmpSuppliers = unique(tdf.Supplier)
        println("selectSupplier", selectedSuppliers)
        println("tmpSuppliers", tmpSuppliers)
        println("searchText",searchText)
        trows = getData(tdf)
    end

end

@page("/", "views/chcsj_pubp_items.jl.html")
# @page("/", "views/chcsj_pubp_items.jl.html")
# @page("/chcsj_pubp_items", "chcsj_pubp_items.jl.html")

end