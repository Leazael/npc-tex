push!(LOAD_PATH, pwd());
using JSON3
using NPCTeX

JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()

aap = JSON3.read(read("./npc-config.json", String), NpcConfig)
aap.concatenators
aap.mappings[25]