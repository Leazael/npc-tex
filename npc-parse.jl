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

function startswithi(s1::AbstractString, s2::Union{AbstractString,Char})::Bool
    return startswith(lowercase(s1), lowercase(s2))
end

function preparse_concatenator(io::IO, concatenators::Vector{Concatenator}, c::Char)::Union{Nothing,Tuple{Concatenator,String}}
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
    
    con.remove        ? buffer = ""           : buffer = con.match
    con.addWhitespace ? buffer = buffer * " " : nothing

    for kk = 1:length(candidates)
        append_value!(candidates[kk].atoms[end], buffer)
    end    
end

function parse_newline!(io::IO, config::NpcConfig, candidates::Vector{Element}, doc::Document)
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


function parse_element!(elem::Element, c::Char)::Bool
    
    atoms, cAtom, nAtoms = elem.atoms, elem.atoms[end], length(elem.atoms)
    mList, nMatches, key = elem.mapping.matchList, length(elem.mapping.matchList), elem.atoms[end].key

    if nAtoms > nMatches # we have run out of matches, so just append it to the current value.
        append_value!(cAtom, c)
        return true
    end

    cMatch, cMatchLength = mList[nAtoms], length(mList[nAtoms][1])
    
    if cMatchLength == length(key) # current key is full, so look for new key or append value
        nextMatch = nMatches > nAtoms ? mList[nAtoms + 1] : nothing
        if !isnothing(nextMatch) && any([startswithi(m, c) for m in nextMatch ]) # new match, 
            push!(atoms, Atom(c))
        else
            append_value!(cAtom, c)
        end
    elseif cMatchLength > length(key) && any([startswithi(m, key * c) for m in cMatch]) # key is incomplete
        append_key!(cAtom, c)
    else 
        return false
    end
    return true
end

function parse_all_elements!(candidates::Vector{Element}, c::Char)
    filter!(elem -> parse_element!(elem, c), candidates)
end


function parse_char!(io::IO, config::NpcConfig, candidates::Vector{Element}, document::Document, c::Char)
    concatenation = preparse_concatenator(io, config.concatenators, c)
    if !isnothing(concatenation)
        parse_concatenator!(io, candidates, concatenation)
    elseif c == '\r' || c == '\n' # end of line reached
        parse_newline!(io, config, candidates, document)
    elseif all(istrivial.(candidates)) && string(c) in config.commentChar # line starts with comment
        skip_until(io, x -> x == '\n'; keep=false)
    else
        parse_all_elements!(candidates, c)
    end

    if eof(io) && !istrivial(candidates)
        push!(document, yield_first(candidates))
    end
end


function parse(io::IO, config::NpcConfig)::Document
    
    candidates = Element.(config.mappings) # create an empty element for each possible mapping.
    document = Document();
        
    while !eof(io)
        parse_char!(io, config, candidates, document, read(io, Char))
    end

    return document
end

function parsefile(path::AbstractString, config::NpcConfig)::Document
    io = open(path)
    data = parse(io, config)
    close(io)
    return data
end