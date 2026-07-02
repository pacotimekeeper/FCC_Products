using HTTP
using JSON

# 1. Define your API destination
# url = "https://httpbin.org"
url = "http://localhost:8080/db"

struct StatusType
    status::String
    message::String
end

struct Person
    name::String
    email::Union{Nothing, String}
    roles::Vector{String}    
end

# 2. Structure your data payload
payload = Dict(
    "name" => "Jane Doe",
    "email" => "jane@example.com",
    "roles" => ["admin", "user"]
)

# 3. Specify headers
headers = [
    "Content-Type" => "application/json"
]

# 4. Serialize dict to JSON string and execute request
response = HTTP.post(url, headers, JSON.json(payload))
p = JSON.parse(String(response.body), Person)
