module SearchItem
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
const df = DataFrame(XLSX.readtable("_all_mappings.xlsx"))
# excludeCols = ["Product_Description(CN)"]

@app begin

    @out tab = "home"
    @out msg1 = "Tab 1 😀"
    @out msg2 = "Tab 2 😀"
    @out msg3 = "Tab 3 😀"

    @out toggle_list = ["red", "green", "yellow"]
    @out toggle_states = []
    @in toggle_name = "toggle"
    @in process = false

    @onchange process begin
        toggle_list = vcat(toggle_list, [toggle_name])
    end


    # @out my_user = User("Julia Coder", 35)
    # @out my_users = [User("Paco Ho", 35), User("Julia Coder", 35)]
    # @out message = "Profile Data"
    @out sdf = df
    @in searchText = ""
    @in btnSearchText = false
    # @in trigger = false
    # @in btnOff = false
    @out theads = names(df)
    @out trows = [OrderedDict()]
    # @out trows = []
    # @out rows = rows
    
    @onbutton btnSearchText begin
        # df = load_object("mappings.jld2")
        tdf = DataFrame(XLSX.readtable("_all_mappings.xlsx"))
        sdf = DataFrames.select(tdf, Not("Product_Description(CN)"))
        sdf.Product_Description = coalesce.(sdf.Product_Description, "missing")
        filter!(:Product_Description => x-> contains(lowercase(x), lowercase(searchText)), sdf)
        theads = names(sdf)
        # @show sdf
        trows = [OrderedDict(pairs(row)) for row in eachrow(sdf)]
    end

    # @onbutton trigger begin
    #     df = load_object("mappings.jld2")
    #     select!(df, Not("Product_Description(CN)"))
    #     theads = names(df)
    #     trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    # end

    # @onbutton btnOff begin
    #     df = DataFrame(XLSX.readtable("data.xlsx"))
    #     theads = names(df)
    #     # select!(df, Not(:Index))
    #     trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    # end

    # @onbutton btnSearchText begin
    #     df = load_object("mappings.jld2")
    #     select!(df, Not("Product_Description(CN)"))
    #     df.Product_Description = coalesce.(df.Product_Description, "NA")
    #     df = filter(:Product_Description => x-> contains(lowercase(x), lowercase(searchText)), df)
    #     trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    # end
end

@page("/search", "search_item.jl.html")

end