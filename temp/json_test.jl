import JSON
using StructTypes
# JSON.parse - JSON to Julia
json = """{"a": 1, "b": null, "c": [1, 2, 3]}"""
jsons = """[
{"a": 1, "b": null, "c": [1, 2, 3]},
{"a": 2, "b": "something", "c": [2, 4, 6]}
]"""

# parse into default Julia types
j = JSON.parse(json)
j2 = JSON.parse(jsons)

JSON.json(j)
# JSON.Object{String, Any} with 3 entries:
#   "a" => 1
#   "b" => nothing
#   "c" => Any[1, 2, 3]

struct MyType
    a::Int
    b::Union{Nothing, String}
    c::Vector{Int}
end
StructTypes.StructType(::Type{MyType}) = StructTypes.Struct()

# parse into a custom type
j = JSON.parse(json, MyType)
j2 = JSON.parse(jsons, Vector{MyType})

# MyType(1, nothing, [1, 2, 3])

# parse into existing container
dict = Dict{String, Any}()
JSON.json(dict)
JSON.parse!(json, dict)

# JSON.parsefile - JSON file to Julia
x = JSON.parsefile("test.json")

# JSON.json - Julia to JSON
JSON.json([2,3])
#  "[2,3]"

# Julia struct to JSON, pretty printed, written to IO (stdout)
JSON.json(stdout, j; pretty=true)
# {
#     "a": 1,
#     "b": null,
#     "c": [
#         1,
#         2,
#         3
#     ]
# }

# test that JSON is valid
JSON.isvalidjson(json)

# Write JSON to file
JSON.json("test.json", j)

# Download json data and parse into a DataFrame
using HTTP, JSON, Tables, DataFrames
resp = HTTP.get("https://raw.githubusercontent.com/altair-viz/vega_datasets/master/vega_datasets/_data/wheat.json")
# null=missing will read json `null` as Julia `missing; `allownan=true` parses all numbers as Float64
df = DataFrame(Tables.dictrowtable(JSON.parse(resp.body; null=missing, allownan=true)))