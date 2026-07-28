module ChcsjPubp
using Main.Config
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

mutable struct Product
    supplier::String
    usecase::String
    code::String
    desc::String
    otNotaQty::Int
    otTenderQty::Int
    openTenderInfo::String
    col1_index::Union{Nothing, Int}
    col2_index::Union{Nothing, Int}
end

gdf = DataFrame()

# APP_PATH = pwd()
function getChcsjPubpMapping()
    mapping = load_object(joinpath(APP_PATH, "data", "mappings.jld2"))
    mapping = filter(["SAP_Code" , "CHCSJ_PUBP(Y/N)"] => ((x, y) -> x!="missing" && y=="Y"), mapping)
    mapping.CHCSJ_物品編號 .= replace.(mapping.CHCSJ_物品編號, " "=> "")

    mapping.tempCol .= ifelse.(mapping.CHCSJ_Modelo .== "missing", mapping.Item_Code, mapping.CHCSJ_Modelo)
    mapping.CHCSJ_物品編號 .= ifelse.(mapping.CHCSJ_物品編號 .== "missing", string.("(missing) for ", mapping.tempCol), mapping.CHCSJ_物品編號)
    
    # mapping.CHCSJ_物品編號 .= ifelse.(mapping.CHCSJ_物品編號 .== "missing", string.("(missing) for ", mapping.CHCSJ_Modelo), mapping.CHCSJ_物品編號)
    mapping.CHCSJ_Product_Description .= ifelse.(mapping.CHCSJ_Product_Description .== "missing", mapping.Product_Description, mapping.CHCSJ_Product_Description)
    
    mapping = flatten(transform(mapping, :CHCSJ_物品編號 => ByRow(x -> string.(split(x, "/"))) => :CHCSJ_物品編號), :CHCSJ_物品編號)
    unique!(mapping, [:Supplier, :用途, :CHCSJ_物品編號])
    mapping = DataFrames.select(mapping, [:Supplier, :用途, :CHCSJ_物品編號, :CHCSJ_Product_Description])
    rename!(x-> replace(x, "CHCSJ_"=> ""), mapping)
    return mapping
end

function refreshDataCache()
    mapping = getChcsjPubpMapping()
    df = load_object("data/all_tenders_notas.jld2")
    df = df[df.Customer .== "CHCSJ", :]

    df1 = df[(df.SAP_Code .!= "missing") .& (df.手動狀態 .== "missing") .& (df.NOTA_手動狀態 .== "missing"), :]

    df1 = df1[df1.NOTA_狀態 .== "尚欠", :]
    otqty = combine(groupby(df1, [:物品編號]) , :NOTA_相差 => sum => :Nota_Qty, :相差 => sum => :Tender_Qty)

    ### No Nota
    df2 = df[df.NOTA_NO .=="missing", :]

    df2 = combine(groupby(df2, [:物品編號, :標書編號]), :要求供貨 => sum => :要求供貨)
    df2 = transform(df2, [:標書編號, :要求供貨] => ByRow((a, b) -> string(a, " (", b, ")")) => :Open_Tender_Info)

    noNotasQty = combine(groupby(df2, [:物品編號]) , :Open_Tender_Info => (x-> join(x,";")) => :Open_Tender_Info)

    df = leftjoin(mapping, otqty, on= :物品編號)
    df = leftjoin(df, noNotasQty,  on= :物品編號)
    for col in [:Nota_Qty, :Tender_Qty]
        df[!, col] .= coalesce.(df[!, col], 0)
    end
    df[!, :Open_Tender_Info] .= coalesce.(df[!, :Open_Tender_Info], "missing")
    sort!(df, [:Supplier, :用途, :Product_Description], rev = false)
    global gdf = df
end

function addColIndice(data)
    data.col1_index = combine(groupby(data, [:Supplier]), eachindex => :col1_index).col1_index
    data.col2_index = combine(groupby(data, [:Supplier, :用途]), eachindex => :col2_index).col2_index
    data
end

getProducts(data) = [Product(row...) for row in eachrow(data)]
refreshDataCache()
# gdf |> addColIndice |> getProducts
# Product[]

@app begin
    @in searchtext = ""
    @in btnsearch = false
    @in btnClearSearch = false

    @in suppliers = unique(gdf.Supplier) |> sort
    @in selectedsuppliers = String[]

    @in cases = unique(gdf.用途) |> sort
    @in selectedcases = String[]

    @out theads = ["Supplier", "用途", "物品編號 -- Product Description", "Nota餘量", "標書餘量"]
    # @out products = gdf |> addColIndice |> getProducts
    @out products = Product[]
    
    for (k, v) in [ (suppliers, selectedsuppliers),
                    (cases, selectedcases)]
        if isempty(v)
            @in v = ["Select"]
        else
            @in v = [first(v)]
        end
    end

    @onbutton btnsearch begin
        # 1. Normalize search term once
        search_term = isempty(searchtext) ? "" : lowercase(strip(searchtext))
        
        # 2. Create the masks using vectorized operations
        # We use map-like comparisons to ensure compatibility with all types (Strings, Missing, etc.)
        
        # Search Mask: Check if join-text contains search_term
        joined_text = lowercase.(string.(gdf.Product_Description, gdf.物品編號, gdf.用途))
        search_mask = map(x -> isempty(search_term) || contains(x, search_term), joined_text)
        
        # Supplier Mask: Check if the row's supplier exists in our selection
        supplier_mask = map(x -> isempty(selectedsuppliers) || x in selectedsuppliers, gdf.Supplier)
        
        # Case/Tag Mask: Check if the row's usage exists in our selection
        case_mask = map(x -> isempty(selectedcases) || x in selectedcases, gdf.用途)

        # 3. Combine Masks (True only if ALL conditions are met)
        # We use standard Julia logical AND for boolean arrays
        final_mask = search_mask .& supplier_mask .& case_mask
        
        # 4. Filter and update products
        filtered_df = gdf[final_mask, :]

        if isempty(filtered_df)
            products = Product[]
        else
            products = filtered_df |> addColIndice |> getProducts
        end
    
    end

    @onchange isready begin
        refreshDataCache()
        # products = gdf |> addColIndice |> getProducts
    end

    @onbutton btnClearSearch begin
        searchtext = ""
        selectedsuppliers = String[]
        selectedcases = String[]
    end
end

@page("/users/chcsj_pubp_items", "views/chcsj_pubp_items.jl.html", layout= "public/layout/chcsj_pubp_items.html")

end