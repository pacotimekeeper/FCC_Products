module SearchItem
using DataFrames, XLSX
using GenieFramework
using JLD2

@genietools

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
        df.Product_Description = coalesce.(df.Product_Description, "NA")
        df = filter(:Product_Description => x-> contains(lowercase(x), lowercase(searchText)), df)
        trows = [OrderedDict(pairs(row)) for row in eachrow(df)]
    end
end

@page("/search", "search_item.jl.html")

end