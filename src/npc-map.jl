Base.strip(s::String, mping::Mapping) = "" * strip(s, [[first(s[1]) for s in mping.paddingChars]; ' '])
enbracket(s::String) = "{" * s * "}"
enbracket(ss::Vector{String}) = join(enbracket.(ss))

function separate_cols(str::String, joinChar::String, mping::Mapping)
    cc = copy(mping.separators)
    ss = [str];

    while !isempty(cc)
        c = popfirst!(cc)
        rr = findfirst(c, ss[end])
        ss = [ss[1:end-1]; ss[end][1:rr[1]-1]; ss[end][rr[end]+1:end]]
    end
    join([strip(s, mping) for s in ss], joinChar)
end

function map_element(elem::Element, config::NpcConfig)::String
    mping = elem.mapping
    latex = mping.latex
    trc = [first(c) for c in config.tableRowChar]
    if mping.isTable
        inputs = String[]
        for a in elem.atoms
            rows = string.(split(a.value, trc))
            push!(inputs, strip(popfirst!(rows), mping ))
            if !isempty(mping.separators)
                for kk = 1:length(rows)
                    rows[kk] = separate_cols(rows[kk], "  &  ", mping) 
                end
            else
                rows = [strip(r, mping) for r in rows]
            end
            if !isempty(rows)
                push!(inputs, join(rows, "  \\\\  "))
            end
        end 
    else
        inputs = [strip(a.value, mping) for a in elem.atoms]
    end

    if !isempty(mping.includeInputs)
        inputs = inputs[mping.includeInputs]
    end

    @assert(length(inputs) == latex.nInputs)
    return "\\" * latex.command * enbracket(inputs)
end

function write(path::String, doc::Document, config::NpcConfig)
    io = open(path, "w");
    for el in doc.elements
        println(io, map_element(el, config))
        println(io)
    end
    close(io)
end