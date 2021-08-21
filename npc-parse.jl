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


function tryparse_concatenator(io, c::Char, buffer::String, concatenators::Vector{Concatenator})
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

function parse(io::Union{IOStream, IOBuffer}, config::NpcConfig)::Document
    
    state = [Element([Atom("","")], m) for m in config.mappings]; # create an empty element for each possible mapping.
    result = Element[];
    newline = true;
        
    while !eof(io)
        c = read(io, Char)
        buffer = ""
        
        if any([startswith(con.match, c) for con in config.concatenators])
            (c, buffer) = tryparse_concatenator(io, c, buffer, config.concatenators)
        else 
            buffer = ""
        end
        
        if c == '\r' || c == '\n'
            if !eof(io) && (last(peekuntil(io, x -> !isspace(x))) * "" in config.tableRowChar)
                # new line is followed by a tableRowChar
                state = [el for el in state if el.mapping.isTable]
                c = ' '
            else
                newline = true;
                if !isempty(state) && !all(isempty.(state[1].atoms))
                    push!(result, state[1])
                end
                state = [Element([Atom("","")], m) for m in config.mappings];
                while !eof(io) && isspace(peek(io, Char))
                    c = read(io, Char) 
                end
            end
        elseif newline && ""*c in config.commentChar
            while peek(io,Char) != '\n'
                c = read(io, Char) 
            end
        else
            newline = false
            for kk=1:length(state)
                s = popfirst!(state);
                mList, key, value, i = s.mapping.matchList, s.atoms[end].key, s.atoms[end].value, length(s.atoms)
                keep, append2value, append2key = true, false, false
    
                if i > length(mList) # we have run out of matches, so just append it to the current value.
                    append2value = true
                elseif length(mList[i][1]) == length(key) # current key is full
                    if length(mList) > i && any([startswith(lowercase(m), lowercase("" * c)) for m in mList[i + 1] ]) # new match, 
                        push!(s.atoms, Atom(""*c,""))
                    else
                        append2value = true
                    end
                elseif length(mList[i][1]) > length(key) && any([startswith(lowercase(m), lowercase(key * c)) for m in mList[i] ])
                    append2key = true
                else 
                    keep = false
                end
                
                if keep 
                    if append2value
                        if isempty(value) || (isspace(last(value)) && isspace(first(buffer * c)))
                            s.atoms[i].value = value * lstrip(buffer * c)
                        else
                            s.atoms[i].value = value * buffer * c
                        end
                    elseif append2key
                        if !isspace(c)
                            s.atoms[i].key = key * buffer * c
                        end
                    end
                    push!(state,s)
                end
            end
        end
    
        if eof(io) && !isempty(state) && !all(isempty.(state[1].atoms))
            push!(result, state[1])
        end
    end

    return Document(result)
end

function parsefile(path::AbstractString, config::NpcConfig)::Document
    
    io = open(path)
    return parse(io,config)
end

