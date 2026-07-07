begin
    using GenieFramework
    using DataFrames, XLSX
    using GenieFramework
    using JLD2
    using OrderedCollections
    using HTTP
    using JSON
    using Genie.Requests
end

begin
# module ChcsjPubp
APP_PATH = pwd()
# using Main.Config
# using Main.Utils
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
# @genietools

# APP_PATH = pwd()
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

    mapping.tempCol .= ifelse.(mapping.CHCSJ_Modelo .== "missing", mapping.Item_Code, mapping.CHCSJ_Modelo)
    mapping.CHCSJ_物品編號 .= ifelse.(mapping.CHCSJ_物品編號 .== "missing", string.("(missing) for ", mapping.tempCol), mapping.CHCSJ_物品編號)
    
    # mapping.CHCSJ_物品編號 .= ifelse.(mapping.CHCSJ_物品編號 .== "missing", string.("(missing) for ", mapping.CHCSJ_Modelo), mapping.CHCSJ_物品編號)
    mapping.CHCSJ_Product_Description .= ifelse.(mapping.CHCSJ_Product_Description .== "missing", mapping.Product_Description, mapping.CHCSJ_Product_Description)
    
    mapping = flatten(transform(mapping, :CHCSJ_物品編號 => ByRow(x -> string.(split(x, "/"))) => :CHCSJ_物品編號), :CHCSJ_物品編號)
    unique!(mapping, :CHCSJ_物品編號)
    
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

function filterData(searchText, selectedSuppliers, selectedCases)
    df = getDf()
    
    text = replace(lowercase(searchText), " "=>"")
    df.joinedCol = lowercase.(string.(df.Product_Description, df.物品編號, df.用途))
    df = df[contains.(df.joinedCol, text), Not(:joinedCol)]
    
    df = addColIndice(df)
    df = filter(:Supplier => in(selectedSuppliers), df)
    df = filter(:用途 => in(selectedCases), df)
    return df
end

function filterByText(searchText, selectedSuppliers, selectedCases)
    df = getDf()
    
    df.joinedCol = lowercase.(string.(df.Product_Description, df.物品編號, df.用途))
    df = df[contains.(df.joinedCol, searchText), Not(:joinedCol)]
    
    df = addColIndice(df)

    df = filter(:Supplier => in(selectedSuppliers), df)
    df = filter(:用途 => in(selectedCases), df)
    return df
end


function filterByCases(searchText, selectedSuppliers, selectedCases)
    df = getDf()
    df = filter(:用途 => in(selectedCases), df)

    df.joinedCol = lowercase.(string.(df.Product_Description, df.物品編號, df.用途))
    df = df[contains.(df.joinedCol, searchText), Not(:joinedCol)]
    
    df = addColIndice(df)
    
    df = filter(:Supplier => in(selectedSuppliers), df)
    return df
end
end
df = getDf()

begin

searchText = ""
btnSearchText = false

suppliers = unique(df.Supplier) |> sort
selectedSuppliers = String[]

# @in selectedSuppliers = unique(df.Supplier) |> sort

caseOptions = unique(df.用途) |> sort
selectedCases = String[]
useCases = filter(x-> x!="missing", unique(df.用途))

theads = ["Supplier", "用途", "物品編號", "Product Description", "餘量"]
products = getDf() |> addColIndice |> getProducts
end

tdf = getDf()

tdf.joinText = lowercase.(string.(tdf.Product_Description, tdf.物品編號, tdf.用途))

selectedSuppliers = ["Baxter", "Medtronic"]
df
results = []

isempty(selectedSuppliers) || eachrow(df)[1].Supplier in selectedSuppliers
for row in eachrow(df)
    println(row.Supplier in selectedSuppliers)
    # match_search = isempty(searchText) || contains(lowercase(row.joinText), searchText)
                # Check multi-select 1 match (empty selection means "show all")
    match_cat = isempty(selectedSuppliers) || row.Supplier in selectedSuppliers
    
    # Check multi-select 2 match (empty selection means "show all")
    # match_tag = isempty(selectedCases) || row.用途 in selectedCases
    
    # if match_search && match_cat && match_tag
    #     push!(results)
    # end
    if match_cat
        push!(results, row)
    end
end

tdf = DataFrame(results)

products = tdf |> addColIndice |> getProducts