module Dummy
using GenieFramework
using Main.Config
@genietools

@app begin
    @out path = APP_PATH
end

function ui()
    cell("$APP_PATH")
end

@page("/dummy", ui)

end