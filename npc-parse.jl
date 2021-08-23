function deepreplace!(a::AbstractVector, b::AbstractVector)
    # this does not seem to exist?
    while !isempty(a)
        pop!(a)
    end
    for x in b 
        push!(a, x)
    end
end

function peekahead(io::IO, n::Int64)::String
    mark(io)
    result = ""
    while !eof(io) && length(result) < n
        result = result * read(io, Char)
    end
    reset(io)
    return result
end

function peekuntil(io::IO, f; startAt=0)
    mark(io)
    skip(io, startAt)
    result = "" * read(io, Char)
    while !eof(io) && !f(last(result))
        result = result * read(io, Char)
    end
    reset(io)
    return result
end

function skip_until(io::IO, f; keep=false)
    while !eof(io) && !f(peek(io, Char))
        read(io, Char)
    end
    if keep
        read(io, Char)
    end
end

function preparse_concatenator(io::IO, c::Char, concatenators::Vector{Concatenator})::Union{Nothing,Tuple{Concatenator,String}}
    for conc in concatenators
        if conc.match == c * peekahead(io, length(conc) - 1)
            tail = peekuntil(io, x -> x == '\n' || !isspace(x); startAt=length(conc) - 1);
            if !isempty(tail) && last(tail) == '\n'
                return (conc, tail)
            end
        end
    end
    return nothing
end

function parse_concatenator!(io::IO, candidates::Vector{Element}, concatenation::Tuple{Concatenator,String})
    con, tail = concatenation
    skip(io, length(con.match) + length(tail) - 1)
    skip_until(io, isspace; keep=false)
    
    con.remove        ? buffer = ""           : buffer = "" * con.match
    con.addWhitespace ? buffer = buffer * " " : nothing

    for kk = 1:length(candidates)
        append_value!(candidates[kk].atoms[end], buffer)
    end    
end

function parse_newline!(io::IO, candidates::Vector{Element}, doc::Document, config::NpcConfig)
    if !eof(io) && (last(peekuntil(io, x -> !isspace(x))) * "" in config.tableRowChar)
        filter!(el -> el.mapping.isTable, candidates)
    else
        if !istrivial(candidates)
            push!(doc, yield_first(candidates))
        end
        deepreplace!(candidates, Element.(config.mappings))
    skip_until(io, x -> !isspace(x); keep=false)
    end
end


function parse_element!(c::Char, elem::Element)::Bool
    
    mList, key, value, i = elem.mapping.matchList, elem.atoms[end].key, elem.atoms[end].value, length(elem.atoms)

    if i > length(mList) # we have run out of matches, so just append it to the current value.
        append_value!(elem.atoms[i], "" * c)
    elseif length(mList[i][1]) == length(key) # current key is full, so look for new key or append value
        if length(mList) > i && any([startswith(lowercase(m), lowercase("" * c)) for m in mList[i + 1] ]) # new match, 
            push!(elem.atoms, Atom("" * c, ""))
        else
            append_value!(elem.atoms[i], "" * c)
        end
    elseif length(mList[i][1]) > length(key) && any([startswith(lowercase(m), lowercase(key * c)) for m in mList[i] ]) # key is incomplete
        append_key!(elem.atoms[i], "" * c)
    else 
        return false
    end
    return true
end

function parse_all_elements!(c::Char, candidates::Vector{Element})
    filter!(elem -> parse_element!(c, elem), candidates)
end

function parse(io::IO, config::NpcConfig)::Document
    
    candidates = Element.(config.mappings) # create an empty element for each possible mapping.
    document = Document();
        
    while !eof(io)
        c = read(io, Char)
        
        concatenation = preparse_concatenator(io, c, config.concatenators)

        if !isnothing(concatenation)
            parse_concatenator!(io, candidates, concatenation)
        elseif c == '\r' || c == '\n' # end of line reached
            parse_newline!(io, candidates, document, config)
        elseif all(istrivial.(candidates)) && string(c) in config.commentChar # line starts with comment
            skip_until(io, x -> x == '\n'; keep=false)
        else
            parse_all_elements!(c, candidates)
        end
    
            if eof(io) && !istrivial(candidates)
        push!(document, yield_first(candidates))
        end
    end

    return document
end

function parsefile(path::AbstractString, config::NpcConfig)::Document
    io = open(path)
    data = parse(io, config)
    close(io)
    return data
end