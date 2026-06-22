using Bonito

# Define a function to create the reactive counter app
function create_app()
    return App(title="FCC Products";indicator=ConnectionIndicator()) do session
        DOM.div(
            DOM.h1("FCC Products"),
            DOM.h2("Distributed Brands"),
            DOM.br(),
            DOM.div(
                style = Styles(
                    "display" => "flex", 
                    "flex-direction" => "row", # /* Places children side-by-side (default) */
                    "justify-content" => "space-around", #/* Centers items horizontally */
                    "gap" => "10px" #/* Adds spacing between items */
                    ),
                DOM.a(href = "https://www.baxter.com/",
                    DOM.img(src="https://cdn.worldvectorlogo.com/logos/baxter.svg"; width="150px")
                ),
                DOM.a(href = "https://www.unitedorthopedic.com/",
                    DOM.img(src="https://www.unitedorthopedic.com/wp-content/uploads/2025/01/United-logo-new.svg"; width="150px")
                ),
                DOM.a(href = "https://www.smith-nephew.com/en",
                    DOM.img(src="https://mc-4895e938-de31-484c-aa80-830364-cdn-endpoint.azureedge.net/-/media/project/smithandnephew/sitesettings/logo.svg?rev=23cce43476814f859aaff33ced056dc9"; width="150px")
                )
            )
        )
    end
end

# Define a function to serve the app on a server
function run_server(app)
    try
        if Sys.islinux()
            server = Server(app, "0.0.0.0", 8080, proxy_url="http://202.175.118.43:6023")
        elseif Sys.isapple()
            server = Server(app, "0.0.0.0", 8080)
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

# Main function to orchestrate the app creation and serving
function (@main)(args)
    app = create_app()
    run_server(app)
end