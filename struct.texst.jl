struct Product
    Purchase_Or_Consign :: String
end
using JLD2
using DataFrames

# 1. Define your struct
struct Person
    name::String
    age::Int
end

struct Product
    sap_code::Any
    supplier::Any
    item_code::Any
    ref_code::Any
end

# 2. Sample DataFrame (Columns must match struct field order)
df = DataFrame(name = ["Alice", "Bob"], age = [25, 30])

# 3. Convert rows to structs
people = map(row -> Person(row...), eachrow(df))
# Returns: Person[Person("Alice", 25), Person("Bob", 30)]
df = load_object("mappings.jld2")
sdf = df[:, 1:4]
products = map(row -> Product(row...), eachrow(df))
println.(names(df))

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

    # Keyword argument constructor helper
    # function Product(;
    #     SAP_Code=nothing, Supplier=nothing, Item_Code=nothing, Ref_Code=nothing,
    #     Product_Description=nothing, Symbol("Product_Description(CN)")=nothing, Brand_Name=nothing, UOM=nothing,
    #     Conv=nothing, Conv_Stock=nothing, Transfer_Price=nothing, Currency=nothing,
    #     Price_Validity=nothing, COO=nothing, Safety_Stock=nothing, Symbol("Shelf_Life(day)")=nothing,
    #     Symbol("Class(Tools/Implants/Medical Device/Dressing)")=nothing, 用途=nothing, Category=nothing,
    #     Sub_Category1=nothing, Sub_Category2=nothing, Symbol("Purchase(Y/N)")=nothing, GTIN=nothing,
    #     銷售團隊=nothing, 銷售業務代表=nothing, Remark=nothing, CHCSJ_Selling_Price=nothing,
    #     CHCSJ_物品編號=nothing, Symbol("CHCSJ_PUBP(Y/N)")=nothing, CHCSJ_483=nothing,
    #     CHCSJ_Modelo=nothing, CHCSJ_Product_Description=nothing, KWH_Selling_Price=nothing,
    #     KWH_品項代碼=nothing, Symbol("KWH_Consign(Y/N)")=nothing, PUMCH_Selling_Price=nothing,
    #     UH_Selling_Price=nothing, YK_Selling_Price=nothing, Gov_Selling_Price=nothing,
    #     Clinic_Selling_Price=nothing, index=nothing, Symbol("CHCSJ_PUBP_Active(Y/N)")=nothing
    # )
    #     new(
    #         SAP_Code, Supplier, Item_Code, Ref_Code,
    #         Product_Description, Symbol("Product_Description(CN)"), Brand_Name, UOM,
    #         Conv, Conv_Stock, Transfer_Price, Currency,
    #         Price_Validity, COO, Safety_Stock, Symbol("Shelf_Life(day)"),
    #         Symbol("Class(Tools/Implants/Medical Device/Dressing)"), 用途, Category,
    #         Sub_Category1, Sub_Category2, Symbol("Purchase(Y/N)"), GTIN,
    #         銷售團隊, 銷售業務代表, Remark, CHCSJ_Selling_Price,
    #         CHCSJ_物品編號, Symbol("CHCSJ_PUBP(Y/N)"), CHCSJ_483,
    #         CHCSJ_Modelo, CHCSJ_Product_Description, KWH_Selling_Price,
    #         KWH_品項代碼, Symbol("KWH_Consign(Y/N)"), PUMCH_Selling_Price,
    #         UH_Selling_Price, YK_Selling_Price, Gov_Selling_Price,
    #         Clinic_Selling_Price, index, Symbol("CHCSJ_PUBP_Active(Y/N)")
    #     )
    # end
end
