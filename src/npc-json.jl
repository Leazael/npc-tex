JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()
JSON3.StructType(::Type{<:Concatenator}) = JSON3.Struct()
JSON3.StructType(::Type{<:Atom}) = JSON3.Struct()
JSON3.StructType(::Type{<:Element}) = JSON3.Struct()
JSON3.StructType(::Type{<:Document}) = JSON3.Struct()

read_config(path::String) = JSON3.read(read(path, String), NpcConfig)

