module ChcsjPubp
using Main.Config
# using Main.Utils
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

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

df = getDf()

@app begin
    @in searchText = ""
    @in btnClearSearch = false

    @in suppliers = unique(df.Supplier) |> sort
    @in selectedSuppliers = String[]

    @in caseOptions = unique(df.用途) |> sort
    @in selectedCases = String[]
    # @out useCases = filter(x-> x!="missing", unique(df.用途))

    @out theads = ["Supplier", "用途", "物品編號", "Product Description", "餘量"]
    @out products = getDf() |> addColIndice |> getProducts
    
    @onbutton btnClearSearch begin
        searchText = ""
        selectedSuppliers = String[]
        selectedCases = String[]
    end

    @onchange searchText, selectedCases, selectedSuppliers begin 
        df = getDf()
    
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