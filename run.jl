
using Bonito

# Create a reactive counter app
app = App() do session
    return DOM.div(
	    DOM.h1("Welcome")
    )
end

# Or serve it on a server
try
    server = Server(app, "0.0.0.0", 8080, proxy_url="http://202.175.118.43:6023")
    println("Server is running")
    wait(server)
catch err
    println(err)
finally
    close(server)
    println("Server is running")
end