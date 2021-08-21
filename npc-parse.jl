function peekahead(io, n)
    mark(io)
    result = "";
    while !eof(io) && length(result) < n
        result = result * read(io, Char)
    end
    reset(io)
    return result
end

function peekuntil(io, f; startAt = 0)
    mark(io)
    skip(io, startAt)
    result = "" * read(io, Char)
    while !eof(io) && !f(last(result))
        result = result * read(io, Char)
    end
    reset(io)
    return result
end


function parse_concatenator(io, c::Char, buffer::String, concatenators::Vector{Concatenator})
    for con in concatenators
        if con.match == c * peekahead(io, length(con.match) - 1)
            tail = peekuntil(io, x -> x == '\n' || !isspace(x); startAt = length(con.match) - 1);
            if !isempty(tail) && last(tail) == '\n'
                skip(io, length(con.match) + length(tail))
                c = read(io, Char)
                while !eof(io) && isspace(c)
                    c = read(io, Char)
                end
                if !con.remove
                    buffer = buffer * con.match;
                end
                if con.addWhitespace
                    buffer = buffer * " "
                end
            end
        end
    end
    return (c, buffer)
end

function parse_newline(io, c::Char, buffer::String, possibleElements::Vector{Element}, result::Vector{Element}, config::NpcConfig)
    if !eof(io) && (last(peekuntil(io, x -> !isspace(x))) * "" in config.tableRowChar)
        possibleElements = [el for el in possibleElements if el.mapping.isTable]
        c = ' '
    else
        if !isempty(possibleElements) && !all(isempty.(possibleElements[1].atoms))
            push!(result, possibleElements[1])
        end
        possibleElements = [Element([Atom("","")], m) for m in config.mappings];
        while !eof(io) && isspace(peek(io, Char))
            c = read(io, Char) 
        end
    end
    return (c, buffer, possibleElements, result)
end

function jump_to_eol(io, c)
    while peek(io,Char) != '\n'
        c = read(io, Char) 
    end
    return c
end

append_key(elem::Element, c::Char)

function parse_element(io, c::Char, elem::Element, buffer::String)
    
    mList, key, value, i = elem.mapping.matchList, elem.atoms[end].key, elem.atoms[end].value, length(elem.atoms)
    keep = true

    if i > length(mList) # we have run out of matches, so just append it to the current value.
        append_value!(elem.atoms[i], buffer, c)
    elseif length(mList[i][1]) == length(key) # current key is full, so look for new key or append value
        if length(mList) > i && any([startswith(lowercase(m), lowercase("" * c)) for m in mList[i + 1] ]) # new match, 
            push!(elem.atoms, Atom(""*c,""))
        else
            append_value!(elem.atoms[i], buffer, c)
        end
    elseif length(mList[i][1]) > length(key) && any([startswith(lowercase(m), lowercase(key * c)) for m in mList[i] ]) # key is incomplete
        append_key!(elem.atoms[i], buffer, c)
    else 
        keep = false
    end

    return (elem, keep)
end


function parse(io::Union{IOStream, IOBuffer}, config::NpcConfig)::Document
    
    possibleElements = [Element([Atom("","")], m) for m in config.mappings]; # create an empty element for each possible mapping.
    result = Element[];
        
    while !eof(io)
        c = read(io, Char)
        buffer = ""
        
        if any([startswith(con.match, c) for con in config.concatenators])
            (c, buffer) = parse_concatenator(io, c, buffer, config.concatenators)
        end
            
        if c == '\r' || c == '\n' # end of line reached
            c, buffer, possibleElements, result = parse_newline(io, c, buffer, possibleElements, result, config)
        elseif all(istrivial.(possibleElements)) && ""*c in config.commentChar # line starts with comment
            jump_to_eol(io, c)
        else
            for kk=1:length(possibleElements)  # cycle through all possible elements
                elem = popfirst!(possibleElements);
                elem, keep = parse_element(io, c, elem, buffer)

                if keep # if the element no longer matches the mapping, we discard it otherwise:
                    push!(possibleElements,elem)
                end
            end
        end
    
        if eof(io) && !all(istrivial.(possibleElements))
            push!(result, possibleElements[1])
        end
    end

    return Document(result)
end

function parsefile(path::AbstractString, config::NpcConfig)::Document
    
    io = open(path)
    return parse(io,config)
end

