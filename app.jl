

module App
#setup of the Genie Framework environment
using GenieFramework
@genietools

# reactive code
@app begin
    @in N = 0
    @out msg = ""
    @onchange N begin
        msg = "N = $N"
    end
end

# UI components
function ui()
    [
        cell([
                p("Enter a number")
                textfield("N", :N )
            ])
        cell([
                bignumber("The value of N is", :N)
            ])
    ]
end

# definition of root route
@page("/", ui)
end
