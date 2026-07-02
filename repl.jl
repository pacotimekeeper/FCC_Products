using GenieFramework
using DataFrames, XLSX
using GenieFramework
using JLD2
using OrderedCollections
@genietools

# 1. Define your standard Julia struct
# mutable struct User
#     name::String
#     age::Int
# end
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