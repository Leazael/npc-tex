using Revise
using JSON3
Revise.includet("NPCTeX.jl");
using .NPCTeX

JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()
JSON3.StructType(::Type{<:Concatenator}) = JSON3.Struct()
JSON3.StructType(::Type{<:Atom}) = JSON3.Struct()
JSON3.StructType(::Type{<:Element}) = JSON3.Struct()
JSON3.StructType(::Type{<:Document}) = JSON3.Struct()

config = JSON3.read(read("npc_config.json", String), NpcConfig)
path = "Einarr_extended.npc";
doc = parsefile(path, config);

for k=1:26
    println(map_element(doc.elements[k], config))
end

write("Einarr2.tex", doc, config)