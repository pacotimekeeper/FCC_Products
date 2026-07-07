module SearchItem2
using DataFrames, XLSX
using GenieFramework
using JLD2

@genietools

struct Product
    sap_code::Any
    supplier::Any
    item_code::Any
    ref_code::Any
    product_description::Any
    product_description_cn::Any
    brand_name::Any
    uom::Any
    conv::Any
    conv_stock::Any
    transfer_price::Any
    currency::Any
    price_validity::Any
    coo::Any
    safety_stock::Any
    shelf_life_day::Any
    class_tools_implants_medical_device_dressing::Any
    use_case::Any             # Converted from 用途
    category::Any
    sub_category1::Any
    sub_category2::Any
    purchase_yn::Any
    gtin::Any
    sales_team::Any           # Converted from 銷售團隊
    sales_rep::Any            # Converted from 銷售業務代表
    remark::Any
    chcsj_selling_price::Any
    chcsj_item_number::Any    # Converted from CHCSJ_物品編號
    chcsj_pubp_yn::Any
    chcsj_483::Any
    chcsj_modelo::Any
    chcsj_product_description::Any
    kwh_selling_price::Any
    kwh_item_code::Any        # Converted from KWH_品項代碼
    kwh_consign_yn::Any
    pumch_selling_price::Any
    uh_selling_price::Any
    yk_selling_price::Any
    gov_selling_price::Any
    clinic_selling_price::Any
    index::Any
    chcsj_pubp_active_yn::Any
end

# 1. Define your standard Julia struct
# mutable struct User
#     name::String
#     age::Int
# end

excludeCols = ["Product_Description(CN)"]

@app begin
    # @out my_user = User("Julia Coder", 35)
    # @out my_users = [User("Paco Ho", 35), User("Julia Coder", 35)]
    # @out message = "Profile Data"

    @in searchText = ""
    @in btnSearchText = false
    @in trigger = false
    @in btnOff = false
    @out theads = []
    @out trows = [OrderedDict()]
    @out products = map(row -> Product(row...), eachrow(load_object("mappings.jld2")))
    # @out rows = rows
    @onbutton trigger begin
        df = load_object("mappings.jld2")
        select!(df, Not("Product_Description(CN)"))
        theads = names(df)
        trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    end

    @onbutton btnOff begin
        df = DataFrame(XLSX.readtable("data.xlsx"))
        theads = names(df)
        # select!(df, Not(:Index))
        trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    end

    @onbutton btnSearchText begin
        df = load_object("mappings.jld2")
        select!(df, Not("Product_Description(CN)"))
        theads = names(df)
        df.Product_Description = coalesce.(df.Product_Description, "NA")
        df = filter(:Product_Description => x-> contains(lowercase(x), lowercase(searchText)), df)
        trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    end
end

@page("/search2", "search_item2.jl.html")

end