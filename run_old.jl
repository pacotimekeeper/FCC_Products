using Bonito
using Markdown
using HTTP
using JSON

struct MyHandler{T}
    handler::T
end

include("style.jl")
include("dom_tags.jl")

sn_chcsj_products = Markdown.parse_file("sn_products.md")
uoc_chcsj_products = Markdown.parse_file("uoc_products.md")

dom_nav = ul(
    li(a("HOME", href = "/")),
    li(a("S&N", href = "/sn")),
    li(a("UOC", href = "/uoc")),
)

# 1. Styles for the <ul> container
# Define a function to create the reactive counter app
app =  App(title="FCC Products";indicator=ConnectionIndicator()) do session
    DOM.div(
        dom_style,
        dom_nav,
        h1("FCC Products"),
        h2("Distributed Brands"),
    )
end

sn = App(title="SN Products";indicator=ConnectionIndicator()) do session
    DOM.div(
        dom_style,
        dom_nav,
        sn_chcsj_products,
    )
end

uoc = App(title="UOC Products";indicator=ConnectionIndicator()) do session
    DOM.div(
        dom_style,
        dom_nav,
        uoc_chcsj_products,
    )
end

# Define a function to serve the app on a server

function Bonito.HTTPServer.apply_handler(handler::MyHandler, context)
    request = context.request
    if request.method == "POST"
        # Read and parse the incoming JSON stream safely
        body_string = String(request.body)
        # println(body_string)
        data = JSON.parse(body_string)
        
        # Look at data or trigger a background task here
        println("Received JSON: ", data)
        
        # Send back a JSON response confirmation
        return HTTP.Response(200,
            ["Content-Type" => "application/json"], 
            body=JSON.json(Dict("status" => "success", "message" => "Data received"))
        )
    else
        return HTTP.Response(405, "Method Not Allowed")
    end
end

db_app = App() do
# db_app = App() do session::Session, request::HTTP.Request
    # if request.method == "POST"
    #     # Read and parse the incoming JSON stream safely
    #     body_string = String(request.body)
    #     # println(body_string)
    #     data = JSON.parse(body_string)
        
    #     # Look at data or trigger a background task here
    #     println("Received JSON: ", data)
        
    #     # Send back a JSON response confirmation
    #     return HTTP.Response(200,
    #         ["Content-Type" => "application/json"], 
    #         body=JSON.json(Dict("status" => "success", "message" => "Data received"))
    #     )
    # else
    #     return HTTP.Response(405, "Method Not Allowed")
    # end

    # println(request.method)
    # println(request.body)
	# path = request.target
    # return DOM.div("You requested: $path")
end

function db_handler(context)
    request = context.request
    
    if request.method != "POST"
        return HTTP.Response(405, "Method Not Allowed")
    end

    # Parse and process data
    data = JSON.parse(String(request.body))
    println("Received JSON: ", data)

    # Return JSON response directly
    return HTTP.Response(
        200, 
        ["Content-Type" => "application/json"], 
        # body = JSON.json(Dict("status" => "success", "message" => "Data received"))
        body = JSON.json(Dict(
            "name" => "Jane Doe",
            "email" => "jane@example.com",
            "roles" => ["admin", "user"]
            )
        )
    )
end

# Main function to orchestrate the app creation and serving
function (@main)(args)
    try
        if Sys.islinux()
            server = Server(app, "0.0.0.0", 8080, proxy_url="http://202.175.118.43:6023")
            route!(server, "/" => app)
            route!(server, "/sn" => sn)
            route!(server, "/uoc" => uoc)
        elseif Sys.isapple()
            server = Server(app, "0.0.0.0", 8080)
            route!(server, "/" => app)
            route!(server, "/sn" => sn)
            route!(server, "/uoc" => uoc)
            route!(server, "/db" => db_handler)
        else
            error("Unknown host")
        end
        
        println("Server is running")
        wait(server)
    catch err
        println(err)
    finally
        close(server)
        println("Server has stopped")
    end
end