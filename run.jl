
using Bonito
# Create a reactive counter app
app = App() do session
    return DOM.div(
	    DOM.h1("Welcome")
    )
end

# Or serve it on a server
server = Server(app, "0.0.0.0", 8080)
wait(server)