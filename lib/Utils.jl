module Utils
using DataFrames

export getIndiceFor
export getIndiceForCols

function getIndiceFor(col::String, df::DataFrame)
    indice = []
    for (i, row) in enumerate(eachrow(df))
        if i == 1
        push!(indice, 0)
        continue
        end
        
        if df[i, col] == df[i-1, col]
            push!(indice, 1)
        else
            push!(indice, 0)
        end
    end
    return indice
end

function getIndiceForCols(col1::String, col2::String,  df::DataFrame)
    indice = []
    for (i, _) in enumerate(eachrow(df))
        # c1 = 0
        # c2 = 0

        if i == 1 ## set show for first row
            push!(indice, (1, 1))
            continue
        end

        if i == 2
            c1 = df[i, col1] == df[i-1, col1] ? 0 : 1 # col this vs this --> dfferent --> show
            c2 = if (c1 == 1 && (df[i, col2] == df[i-1, col2]))
                1
                else
                0
            end
            push!(indice, (c1, c2))
            continue
        end
        
        c1 = df[i, col1] == df[i-1, col1] ? 0 : 1
        c2 = if c1 == 0 && df[i, col2] == df[i-1, col2]
                0
            else
                1
            end
        push!(indice, (c1, c2))
    end
    return indice
end

end