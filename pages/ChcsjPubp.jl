module ChcsjPubp
using Main.Config
# using Main.Utils
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

APP_PATH = pwd()
mutable struct Product
    supplier::String
    use_case::String
    code::String
    desc::String
    ot_qty::Int
    col1_index::Int
    col2_index::Int
end
# APP_PATH = pwd()
function getMappingDf()
    mapping = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
    mapping = filter(["SAP_Code" , "CHCSJ_PUBP(Y/N)"] => ((x, y) -> x!="missing" && y=="Y"), mapping)
    mapping.CHCSJ_物品編號 .= replace.(mapping.CHCSJ_物品編號, " "=> "")
    mapping = flatten(transform(mapping, :CHCSJ_物品編號 => ByRow(x -> string.(split(x, "/"))) => :CHCSJ_物品編號), :CHCSJ_物品編號)
    unique!(mapping, :CHCSJ_物品編號)
    mapping.CHCSJ_Product_Description .= ifelse.(mapping.CHCSJ_Product_Description .== "missing", mapping.Product_Description, mapping.CHCSJ_Product_Description)
    
    mapping = DataFrames.select(mapping, [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description])
    rename!(x-> replace(x, "CHCSJ_"=> ""), mapping)
    return mapping
end

function getTendersDf()
    tenders = load_object(joinpath(APP_PATH, "data", "all_tenders.jld2"))
    tenders = tenders[tenders.標書_SAP狀態 .=="尚欠", [:物品編號, :相差]]
    # tenders[isnothing.(tenders.相差) |> sum 
    return combine(groupby(tenders, :物品編號), :相差 => sum => :Outstanding_Qty)
end

function getDf()
    df = leftjoin(getMappingDf(), getTendersDf(), on =:物品編號)
    df.Outstanding_Qty = coalesce.(df.Outstanding_Qty, 0)
    sort!(df, [:Supplier, :用途, :Product_Description], rev = false)
    return df
end

getProducts(data) = [Product(row...) for row in eachrow(data)]

function addColIndice(data)
    data.col1_index = combine(groupby(data, [:Supplier]), eachindex => :col1_index).col1_index
    data.col2_index = combine(groupby(data, [:Supplier, :用途]), eachindex => :col2_index).col2_index
    data
end

function filterData(searchText, selectedSuppliers)
    df = getDf()
    text = replace(lowercase(searchText), " "=>"")
    df.joinedCol = lowercase.(string.(df.Product_Description, df.物品編號, df.用途))
    df = df[contains.(df.joinedCol, text), Not(:joinedCol)]
    df = addColIndice(df)
    df = filter(:Supplier => in(selectedSuppliers), df)
    return df
end

function processDf()
    tdf = getDf()
    return addColIndice(tdf)
end

df = getDf()

@app begin
    @out suppliers = unique(df.Supplier) |> sort
    @in selectedSuppliers = unique(df.Supplier) |> sort

    @in searchText = ""
    @in btnSearchText = false

    @in selectedCase = ""
    @out useCases = filter(x-> x!="missing", unique(df.用途))

    @out theads = ["Supplier", "用途", "物品編號", "Product Description", "餘量"]
    @out products = getDf() |> addColIndice |> getProducts
    
    @onchange selectedCase begin
        println(selectedCase)
    end

    @onchange selectedSuppliers begin
        products = filterData(searchText, selectedSuppliers) |> getProducts
    end
    
    @onbutton btnSearchText begin
        products = filterData(searchText, selectedSuppliers) |> getProducts
    end
end

@page("/", "views/chcsj_pubp_items.jl.html", layout= "public/layout/chcsj_pubp_items.html")

end