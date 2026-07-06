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
    col1_index::Int
    col2_index::Int
end

function getDf()
    mapping = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
    mapping = filter(["SAP_Code" , "CHCSJ_PUBP(Y/N)"] => ((x, y) -> x!="missing" && y=="Y"), mapping)
    mapping = flatten(transform(mapping, :CHCSJ_物品編號 => ByRow(x -> split(x, "/")) => :CHCSJ_物品編號), :CHCSJ_物品編號)
    unique!(mapping, :CHCSJ_物品編號)
    sort!(mapping, [:Supplier, :用途, :CHCSJ_Product_Description], rev = false)
    mapping = DataFrames.select(mapping, [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description])
    return mapping
end

getProducts(data) = [Product(row...) for row in eachrow(data)]

function addColIndice(data)
    data.col1_index = combine(groupby(data, [:Supplier]), eachindex => :col1_index).col1_index
    data.col2_index = combine(groupby(data, [:Supplier, :用途]), eachindex => :col2_index).col2_index
    data
end

function filterData(searchText, selectedSuppliers)
    df = getDf()
    text = lowercase(searchText)
    df.joinedCol = lowercase.(string.(df.CHCSJ_Product_Description, df.CHCSJ_物品編號, df.用途))
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

    @out theads = ["Supplier", "用途", "物品編號", "Product Description"]
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