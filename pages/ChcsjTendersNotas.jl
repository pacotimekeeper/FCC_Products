module ChcsjTendersNotas
using Main.Config
using DataFrames, XLSX
using Dates
using GenieFramework
using JLD2
using OrderedCollections
@genietools


oldnames = ["Customer", "物品編號", "標書編號", "SAP_Code", "型號", "成份/物品名稱", "Product_Description", "單價", "要求供貨", "已供", "相差", "狀態", "手動狀態", "NOTA_NO",	"NOTA_日期", "NOTA_報購量數", "NOTA_已供",	"NOTA_相差", "NOTA_狀態", "NOTA_手動狀態", "Stock_Qty", "Stock_Info", "PO_Qty",	"PO_Info"]
newnames = ["customer", "custcode", "tenderno", "sapcode", "model", "ingredient", "productdesc", "unitprice", "reqqty", "supplied", "diff", "status", "mstatus", "notano", "notadate", "notareqqty", "notasupplied", "notadiff", "notastatus", "notamstatus", "stockqty", "stockinfo", "poqty", "poinfo"]
newcols = Dict(zip(oldnames, newnames))

mutable struct Nota
    customer::String
    custcode::String
    tenderno::String
    sapcode::String
    model::String
    ingredient::String
    productdesc::String
    unitprice::Float64
    reqqty::Float64
    supplied::Int64
    diff::Int64
    status::String
    mstatus::String
    notano::String
    notadate::String
    notareqqty::Float64
    notasupplied::Int64
    notadiff::Int64
    notastatus::String
    notamstatus::String
    stockqty::Int64
    stockinfo::String
    poqty::Int64
    poinfo::String
end

# 1. Global Variable to hold the "Master" DataFrame
gdf = DataFrame()

function refreshDataCache()
    mappings = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
    chcsjPubpItems = filter("CHCSJ_PUBP(Y/N)" => ==("Y"), mappings).SAP_Code

    notas = load_object("data/all_tenders_notas.jld2")
    notas = flatten(transform(notas, :SAP_Code => ByRow(x -> string.(split(x, "/"))) => :SAP_Code), :SAP_Code)
    notas = notas[.!in.(notas.SAP_Code, Ref(chcsjPubpItems)), ["Customer", "NOTA_NO", "NOTA_報購量數", "NOTA_已供", "NOTA_手動狀態", "NOTA_日期", "NOTA_狀態", "NOTA_相差", "SAP_Code", "單價", "型號", "已供", "成份/物品名稱", "手動狀態", "標書編號", "物品編號", "狀態", "相差", "要求供貨"]]
        
    stock = load_object("data/inventories.jld2")
    stock.EXP .= Date.(stock.EXP, dateformat"yyyy-mm-dd")
    stock = stock[stock.EXP .> today(), :]
    stock.Stock_Info .= string.("(", stock.數量, ") ", stock.LOT, " @", stock.EXP)
    stock = combine(groupby(stock, :SAP_Code), :數量 => sum => :Stock_Qty, :Stock_Info => (x-> join(x, ";\n")) => :Stock_Info)
    
    po = load_object("data/pos.jld2")
    po.Info .= string.("(", po.未結數量, ") PO",po.PO文件號碼, " @", po.過帳日期)
    po = combine(groupby(po, :SAP_Code), :PO數量 => sum => :PO_Qty, :Info => (x-> join(x, ";\n")) => :PO_Info)

    df = leftjoin(notas, stock, on=:SAP_Code)
    df = leftjoin(df, po, on=:SAP_Code)
    df = leftjoin(df, mappings[!, [:SAP_Code, :Product_Description]], on=:SAP_Code)
    
    #str col
    intcols = ["Stock_Qty", "PO_Qty"]
    for col in intcols
        df[!, col] .= coalesce.(df[!, col], 0)
    end
    
    strcols = ["Stock_Info", "PO_Info", "Product_Description"]
    for col in strcols
        df[!, col] .= string.(coalesce.(df[!, col], "missing"))
    end
    
    select!(df, ["Customer", "物品編號", "標書編號", "SAP_Code", "型號", "成份/物品名稱", "Product_Description", "單價", "要求供貨", "已供", "相差", "狀態", "手動狀態", "NOTA_NO",	"NOTA_日期", "NOTA_報購量數", "NOTA_已供",	"NOTA_相差", "NOTA_狀態", "NOTA_手動狀態", "Stock_Qty", "Stock_Info", "PO_Qty",	"PO_Info"])
    # rename!(df, newcols)
    global gdf = df
end


getnotas(data) = [Nota(row...) for row in eachrow(data)]

refreshDataCache()

@app begin
    @in searchtext = ""
    @in statuses = unique(gdf.狀態) |> sort
    # @in statuses = unique(getdf().狀態) |> sort
    @in selectedstatuses = String[]
    
    # @in suppliers = unique(getdf().Supplier) |> sort
    # @in selectedSuppliers = String[]


    # @out theads = names(rename(getdf(), Dict(zip(newnames, oldnames))))
    @out theads = names(gdf)
    # @out theads = names(getdf())
    @out notas = gdf |> getnotas
    # @out notas = getdf() |> getnotas
    @onchange searchtext, selectedstatuses begin
        # df = getdf()
    
        # 1. Normalize search term once
        searchterm = isempty(searchtext) ? "" : lowercase(strip(searchtext))
        searchterm = replace(searchterm, "-" => "")
        
        # 2. Create the masks using vectorized operations
        # We use map-like comparisons to ensure compatibility with all types (Strings, Missing, etc.)
        
        # Search Mask: Check if join-text contains search_term
        joinedtext = replace.(lowercase.(string.(gdf.SAP_Code, gdf.物品編號, gdf.Product_Description)), Ref("-"=> ""))
        searchmask = map(x -> isempty(searchterm) || contains(x, searchterm), joinedtext)
        
        # Supplier Mask: Check if the row's supplier exists in our selection
        statusmask = map(x -> isempty(selectedstatuses) || x in selectedstatuses, gdf.狀態)

        
        # Case/Tag Mask: Check if the row's usage exists in our selection
        # case_mask = map(x -> isempty(selectedCases) || x in selectedCases, df.用途)

        # 3. Combine Masks (True only if ALL conditions are met)
        # We use standard Julia logical AND for boolean arrays
        # final_mask = search_mask .& supplier_mask .& case_mask
        finalmask = searchmask .& statusmask
        # finalmask = searchmask
        
        # 4. Filter and update products
        fdf = gdf[finalmask, :]

        if isempty(fdf)
            notas = Nota[]
        else
            notas = fdf |> getnotas
        end
    end
end

@page("/users/tenders_notas", "views/chcsj_tenders_notas.jl.html", layout= "public/layout/chcsj_tenders_notas.html")

end