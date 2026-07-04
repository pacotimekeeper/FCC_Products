module ChcsjPubp
using Main.Config
using Main.Utils
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

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
    # mapping = filter("CHCSJ_PUBP(Y/N)" => x-> !ismissing(x) && x =="Y", mapping)
    unique!(mapping, :CHCSJ_Modelo)
    sort!(mapping, [:Supplier, :用途, :CHCSJ_Product_Description], rev = false)
    # transform!(groupby(df, :Supplier), nrow => :count)
    mapping = DataFrames.select(mapping, [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description])
    return mapping
end

function getIndicedDf(col1, col2)
    df = getDf()
    df.indice = getIndiceForCols(col1, col2, df)
    transform!(df, :indice => AsTable)
    select!(df, Not(:indice))
    return df
end

# function getData(data)
#     return [OrderedDict(pairs(row)) for row in eachrow(data)]
# end

function getProducts(data)
    [Product(row...) for row in eachrow(data)]
end

function filterByText(searchText)
    tdf = getDf()
    text = lowercase(searchText)
    # tdf = filter(:Supplier => in(suppliers), tdf)
    tdf.joinedCol = lowercase.(string.(tdf.CHCSJ_Product_Description, tdf.CHCSJ_物品編號, tdf.用途))
    return tdf[contains.(tdf.joinedCol, text), Not(:joinedCol)]
end

function processDf()
    tdf = getDf()
    tdf.col1_index = combine(groupby(tdf, [:Supplier]), eachindex => :col1_index).col1_index
    tdf.col2_index = combine(groupby(tdf, [:Supplier, :用途]), eachindex => :col2_index).col2_index
    tdf
end

const df = getDf()

@app begin
    @out suppliers = unique(df.Supplier)
    @in selectedSuppliers = unique(df.Supplier)
    @out products = getProducts(processDf())

    @in searchText = ""
    @in btnSearchText = false
    @out theads = ["Supplier", "用途", "物品編號", "Product Description"]
    
    @onchange selectedSuppliers begin
        tdf = getDf()
        text = lowercase(searchText)
        tdf.joinedCol = lowercase.(string.(tdf.CHCSJ_Product_Description, tdf.CHCSJ_物品編號, tdf.用途))
        tdf = tdf[contains.(tdf.joinedCol, text), Not(:joinedCol)]
        tdf.col1_index = combine(groupby(tdf, [:Supplier]), eachindex => :col1_index).col1_index
        tdf.col2_index = combine(groupby(tdf, [:Supplier, :用途]), eachindex => :col2_index).col2_index
        tdf = filter(:Supplier => in(selectedSuppliers), tdf)
        products = getProducts(tdf)
    end
    
    @onbutton btnSearchText begin
        tdf = getDf()
        text = lowercase(searchText)
        tdf.joinedCol = lowercase.(string.(tdf.CHCSJ_Product_Description, tdf.CHCSJ_物品編號, tdf.用途))
        tdf = tdf[contains.(tdf.joinedCol, text), Not(:joinedCol)]
        tdf.col1_index = combine(groupby(tdf, [:Supplier]), eachindex => :col1_index).col1_index
        tdf.col2_index = combine(groupby(tdf, [:Supplier, :用途]), eachindex => :col2_index).col2_index
        tdf = filter(:Supplier => in(selectedSuppliers), tdf)
        products = getProducts(tdf)
    end
end

@page("/", "views/chcsj_pubp_items.jl.html")

end