using Bonito
using Markdown

DOM.table
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