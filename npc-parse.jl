function parse(stream::IOStream)::Document
    
    return document
end

function parsefile(path::AbstractString)::Document
    
    io = open(path)
    return parse(io)
end

