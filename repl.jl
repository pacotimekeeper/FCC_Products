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

APP_PATH = pwd()

mapping = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
mapping = filter(["SAP_Code" , "CHCSJ_PUBP(Y/N)"] => ((x, y) -> x!="missing" && y=="Y"), mapping)
mapping = flatten(transform(mapping, :CHCSJ_物品編號 => ByRow(x -> split(x, "/")) => :CHCSJ_物品編號), :CHCSJ_物品編號)

code = "2309053446"
code = "2309056038"
in(code, mapping.CHCSJ_物品編號)

filter(x -> contains(x, code), mapping.CHCSJ_物品編號)


unique!(mapping, [:CHCSJ_物品編號, :CHCSJ_Modelo])
sort!(mapping, [:Supplier, :用途, :CHCSJ_Product_Description], rev = false)
mapping = DataFrames.select(mapping, [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description])
return mapping
df = getDf()
filter(x-> x!="missing", unique(df.用途))

# 1. Define your standard Julia struct
mutable struct Product
    supplier::String
    use_case::String
    code::String
    desc::String
end
APP_PATH = pwd()
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

tdf = getDf()
tdf.col1_index = combine(groupby(tdf, [:Supplier]), eachindex => :col1_index).col1_index
tdf.col2_index = combine(groupby(tdf, [:Supplier, :用途]), eachindex => :col2_index).col2_index
tdf

dfs = []
groupby(tdf, [:Supplier, :用途])[2]
tdf.index = 1: size(tdf)[1]


function getIndiceForCols(col1::String, col2::String,  df::DataFrame)
    indice = []
    for (i, _) in enumerate(eachrow(df))
        # c1 = 0
        # c2 = 0

        if i == 1
            push!(indice, (1, 1))
            continue
        end

        if i == 2
            c1 = df[i, col1] == df[i-1, col1] ? 0 : 1
            c2 = if c1 == 1 && (df[i, col2] == df[i-1, col2])
                1
                else
                0
            end
            push!(indice, (c1, c2))
            continue
        end
        
        c1 = df[i, col1] == df[i-1, col1] ? 0 : 1
        c2 = if c1 == 0 && df[i, col2] == df[i-1, col2]
                0
            else
                1
            end
        push!(indice, (c1, c2))
    end
    return indice
end

tdf = filter(:Supplier => in(["Medtronic" , "United Orthopedic Corporation"]), tdf)

tdf.indices = getIndiceForCols("Supplier", "用途", tdf)
transform!(tdf, :indices => AsTable)
select!(tdf, Not(:indices))


tdf.Supplier |> unique
"Medtronic" , "Smith & Nephew" , "United Orthopedic Corporation"
st = "str"
( = 1, b = 2)

tdf = processDf()
indice = []
for (i, row) in enumerate(eachrow(tdf))
    if i == 1
       push!(indice, 0)
       continue
    end
    
    if tdf[i, :Supplier] == tdf[i-1, :Supplier]
        push!(indice, 1)
    else
        push!(indice, 0)
    end
end

tdf.index .= indice
rows = [Product(row...) for row in eachrow(tdf)]


rows[1].supplier
# transform1(groupby(df, :Supplier), count => :count)
# combine(groupby(daf, :Supplier), nrow => :count) |> transform
# transform!(groupby(df, :Supplier), nrow => :count)
# combine(row, :Supplier => count)

indice
eachrow(rows)

my_users = []
df = DataFrame(XLSX.readtable("_all_mappings.xlsx"))
df = filter("CHCSJ_PUBP(Y/N)" => x-> !ismissing(x) && x =="Y", df)
select!(df, :Supplier, :CHCSJ_Modelo, :用途, :CHCSJ_Product_Description)

gs = groupby(df, :Supplier)
sdf = unique(gs[1], :CHCSJ_Modelo)
gdf = groupby(sdf, :用途)
df = DataFrame(gdf[1])
# 用途	Category	Sub_Category1	Sub_Category2

# for (k,v) in pairs(gs)
#     println(v)
#     println(k.Supplier)
# end
# keys(gs)
# names(df)

# SAP_Code
# Supplier
# Item_Code	Ref_Code	Product_Description	Product_Description(CN)	Brand_Name	UOM	Conv	Conv_Stock	Transfer_Price	Currency	Price_Validity	COO	Safety_Stock	Shelf_Life(day)	Class(Tools/Implants/Medical Device/Dressing)	用途	Category	Sub_Category1	Sub_Category2	Purchase(Y/N)	GTIN	銷售團隊	銷售業務代表	Remark	CHCSJ_Selling_Price	
# CHCSJ_物品編號	
# CHCSJ_PUBP(Y/N)	CHCSJ_483	CHCSJ_Modelo	CHCSJ_Product_Description	KWH_Selling_Price	KWH_品項代碼	KWH_Consign(Y/N)	PUMCH_Selling_Price	UH_Selling_Price	YK_Selling_Price	Gov_Selling_Price	Clinic_Selling_Price	index	CHCSJ_PUBP_Active(Y/N)

using JSON
using HTTP
try
# df = load_object(joinpath(pwd(), "temp_data", "mappings.jld2"))
    df = XLSX.readtable("_all_mappings.xlsx", "Sheet1") |> DataFrame
    jsonPayload = JSON.json(df)
    # POST payload as raw binary data stream with correct content-type header
    response = HTTP.post(
        "http://127.0.0.1:8080/jsonpayload/mappings",
        ["Content-Type" => "application/json"],
        jsonPayload
    # verbose = 0
    );
    println("Upload Status: ", response.status)
    println("Server Response: ", String(response.body))
    println("Client success")
catch e
    println("Upload failed: ", e)
end

curDir = @__DIR__
parentDir = dirname(curDir)

df = load_object("data/mappingsxx.jld2")
describe(df)
@. df[isnothing(df.Brand_Name), :]
@. df[ismissing(df.Brand_Name), :]

