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
    col1_index::Int
    col2_index::Int
end

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

# APP_PATH = pwd()
function getdf()
    mapping = getChcsjPubpMapping()
    df = load_object("data/all_tenders_notas.jld2")

    df = df[df.Customer .== "CHCSJ", :]
    # for col in [:Nota_SAP狀態, :Nota_手動狀態]
    #     df[!, col] .= coalesce.(df[!, col], "missing")
    # end

    # df.標書_要求供貨 = ifelse.(isnothing.(df.標書_要求供貨), 0, df.標書_要求供貨) ### Need type check in DataLoad
    # df.標書_相差 = ifelse.(isnothing.(df.標書_相差), 0, df.標書_相差) ### Need type check in DataLoad
    # df.Nota_相差 = ifelse.(isnothing.(df.Nota_相差), 0, df.標書_相差) ### Need type check in DataLoad
    # df.NOTA_NO = ifelse.(isnothing.(df.NOTA_NO), "missing", df.NOTA_NO) ### Need type check in DataLoad

    ## df1 Has nota

    df1 = df[(df.SAP_Code .!= "missing") .& (df.手動狀態 .== "missing") .& (df.NOTA_手動狀態 .== "missing"), :]

    df1 = df1[df1.NOTA_狀態 .== "尚欠", :]
    otqty = combine(groupby(df1, [:物品編號]) , :NOTA_相差 => sum => :Nota_Qty, :相差 => sum => :Tender_Qty)

    ### No Nota
    df2 = df[df.NOTA_NO .=="missing", :]

    df2 = combine(groupby(df2, [:物品編號, :標書編號]), :要求供貨 => sum => :要求供貨)
    df2 = transform(df2, [:標書編號, :要求供貨] => ByRow((a, b) -> string(a, " (", b, ")")) => :Open_Tender_Info)

    noNotasQty = combine(groupby(df2, [:物品編號]) , :Open_Tender_Info => (x-> join(x,";")) => :Open_Tender_Info)

    # unique(otqty, :物品編號)
    # unique(noNotasQty, :物品編號)


    df = leftjoin(mapping, otqty, on= :物品編號)
    df = leftjoin(df, noNotasQty,  on= :物品編號)
    for col in [:Nota_Qty, :Tender_Qty]
        df[!, col] .= coalesce.(df[!, col], 0)
    end
    df[!, :Open_Tender_Info] .= coalesce.(df[!, :Open_Tender_Info], "missing")
    sort!(df, [:Supplier, :用途, :Product_Description], rev = false)
    return df
end

function addColIndice(data)
    data.col1_index = combine(groupby(data, [:Supplier]), eachindex => :col1_index).col1_index
    data.col2_index = combine(groupby(data, [:Supplier, :用途]), eachindex => :col2_index).col2_index
    data
end

getProducts(data) = [Product(row...) for row in eachrow(data)]

# idf = getdf()

@app begin
    @in searchText = ""
    @in btnClearSearch = false

    @in suppliers = unique(getdf().Supplier) |> sort
    @in selectedSuppliers = String[]

    @in caseOptions = unique(getdf().用途) |> sort
    @in selectedCases = String[]
    # @out useCases = filter(x-> x!="missing", unique(df.用途))

    @out theads = ["Supplier", "用途", "物品編號 -- Product Description", "Nota餘量", "標書餘量"]
    @out products = getdf() |> addColIndice |> getProducts
    
    @onbutton btnClearSearch begin
        searchText = ""
        selectedSuppliers = String[]
        selectedCases = String[]
    end

    @onchange searchText, selectedCases, selectedSuppliers begin 
        df = getdf()
    
        # 1. Normalize search term once
        search_term = isempty(searchText) ? "" : lowercase(strip(searchText))
        
        # 2. Create the masks using vectorized operations
        # We use map-like comparisons to ensure compatibility with all types (Strings, Missing, etc.)
        
        # Search Mask: Check if join-text contains search_term
        joined_text = lowercase.(string.(df.Product_Description, df.物品編號, df.用途))
        search_mask = map(x -> isempty(search_term) || contains(x, search_term), joined_text)
        
        # Supplier Mask: Check if the row's supplier exists in our selection
        supplier_mask = map(x -> isempty(selectedSuppliers) || x in selectedSuppliers, df.Supplier)
        
        # Case/Tag Mask: Check if the row's usage exists in our selection
        case_mask = map(x -> isempty(selectedCases) || x in selectedCases, df.用途)

        # 3. Combine Masks (True only if ALL conditions are met)
        # We use standard Julia logical AND for boolean arrays
        final_mask = search_mask .& supplier_mask .& case_mask
        
        # 4. Filter and update products
        filtered_df = df[final_mask, :]

        if isempty(filtered_df)
            products = Product[]
        else
            products = filtered_df |> addColIndice |> getProducts
        end
    end
end

@page("/users/chcsj_pubp_items", "views/chcsj_pubp_items.jl.html", layout= "public/layout/chcsj_pubp_items.html")

end