JSON3.StructType(::Type{<:NpcConfigJSON}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:MappingStrict}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()
JSON3.StructType(::Type{<:Concatenator}) = JSON3.Struct()
JSON3.StructType(::Type{<:Atom}) = JSON3.Struct()
JSON3.StructType(::Type{<:Element}) = JSON3.Struct()
JSON3.StructType(::Type{<:Document}) = JSON3.Struct()
JSON3.StructType(::Type{<:DocumentSettings}) = JSON3.Struct()

read_config(path::String)::NpcConfigJSON = JSON3.read(read(path, String), NpcConfigJSON)

function read_and_simplify(data::NpcConfigJSON)::Tuple{DocumentSettings, Vector{MappingStrict}}
    return (data.documentSettings, simplify(data.mappings))
end

read_and_simplify(path::String)::Tuple{DocumentSettings, Vector{MappingStrict}} = read_and_simplify(read_config(path))

NpcConfig(path::String)::NpcConfig = NpcConfig(read_and_simplify(path)...)