using GenieFramework
using DataFrames, XLSX
println(p())
println(cell([
p("Enter a number")
p("b")
]))

th()


function htmlTable(df::DataFrame)
df = XLSX.readtable("data.xlsx") |> DataFrame

thead(tr(th.(names(df))))
header = thead(tr(th.(names(df))...))

values(eachrow(df)[1])
# Generate Table Body Rows
rows = map(eachrow(df)) do row
    tr(td.(values(row)))
end

table(header, tbody(rows...))
end

htmlTable(df)