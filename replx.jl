
using DotEnv
using FCC
import FCC.Utils: responsecontent
import FCC.DataTransform
import FCC.DataExtract: haspermission, login
import FCC.Config: CUSTOMER_SYMBOL_MAP, APP_PATH, FILESERVER, PARA_FOLDERS, FCC_SURGICAL
using HTTP, Gumbo, Cascadia, StringEncodings

# begin
using Dates
using OrderedCollections
using GenieFramework
using Match
using JLD2
using Revise
using JSON
# using JSON
# using SQLite
# using GenieFramework

using DataFrames, XLSX, Chain, Match, JLD2

# using JLD2
# using OrderedCollections
APP_PATH = pwd()

# begin
function getChcsjPubpMapping()
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

mapping = getChcsjPubpMapping()
df = load_object("data/all_tenders_notas.jld2")

df = df[df.Customer .== "CHCSJ", :]

for col in [:Nota_SAP狀態, :Nota_手動狀態]
    df[!, col] .= coalesce.(df[!, col], "missing")
end

df.標書_要求供貨 = ifelse.(isnothing.(df.標書_要求供貨), 0, df.標書_要求供貨) ### Need type check in DataLoad
df.標書_相差 = ifelse.(isnothing.(df.標書_相差), 0, df.標書_相差) ### Need type check in DataLoad
df.Nota_相差 = ifelse.(isnothing.(df.Nota_相差), 0, df.標書_相差) ### Need type check in DataLoad
df.NOTA_NO = ifelse.(isnothing.(df.NOTA_NO), "missing", df.NOTA_NO) ### Need type check in DataLoad

## df1 Has nota
df1 = df[(df.SAP_Code .!= "missing") .& (df.標書_手動狀態 .== "missing") .& (df.Nota_手動狀態 .== "missing"), :]

df1 = df1[df1.Nota_SAP狀態 .== "尚欠", :]
otqty = combine(groupby(df1, [:物品編號]) , :Nota_相差 => sum => :Nota_Qty, :標書_相差 => sum => :Tender_Qty)

### No Nota
df2 = df[df.NOTA_NO .=="missing", :]

df2 = combine(groupby(df2, [:物品編號, :標書編號]), :標書_要求供貨 => sum => :標書_要求供貨)
df2 = transform(df2, [:標書編號, :標書_要求供貨] => ByRow((a, b) -> string(a, " (", b, ")")) => :Open_Tender_Info)

noNotasQty = combine(groupby(df2, [:物品編號]) , :Open_Tender_Info => (x-> join(x,";")) => :Open_Tender_Info)

unique(otqty, :物品編號)
unique(noNotasQty, :物品編號)


df = leftjoin(mapping, otqty, on= :物品編號)
df = leftjoin(df, noNotasQty,  on= :物品編號)
for col in [:Nota_Qty, :Tender_Qty]
    df[!, col] .= coalesce.(df[!, col], 0)
end
df[!, :Open_Tender_Info] .= coalesce.(df[!, :Open_Tender_Info], "missing")
sort!(df, [:Supplier, :用途, :Product_Description], rev = false)
return df