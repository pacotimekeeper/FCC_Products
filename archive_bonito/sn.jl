using Bonito
using DataFrames, XLSX
include("dom_tags.jl")
include("style.jl")

df = DataFrame(XLSX.readtable("data.xlsx"))
data = Tables.rowtable(df)

# 3. Create the Bonito App
app = App() do session
    headers = tr(map(x-> th(x), names(df)))
    # Generate table headers
    
    # Generate table rows dynamically from the dummy data
    rows = map(data) do row
        tr(
            row.Index == 1 ? td(row.Category) : td(),
            td(string(row.Index)),
            td(row.Price),
            td(row.Code),
            td(row.Product_Description)
        )
    end
    
    # 4. Construct the layout and inject inline CSS styling
    return DOM.div(
        h2("Team Member Directory"),
        table(
            table_style,
            headers,
            rows...
        ),
    )
end

# 5. Start the server on port 8081
Server(app, "127.0.0.1", 8081)
close(app)