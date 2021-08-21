using Revise
using JSON3
using Test
include("NPCTeX.jl");
using .NPCTeX

JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()
JSON3.StructType(::Type{<:Concatenator}) = JSON3.Struct()
JSON3.StructType(::Type{<:Atom}) = JSON3.Struct()
JSON3.StructType(::Type{<:Element}) = JSON3.Struct()
JSON3.StructType(::Type{<:Document}) = JSON3.Struct()

config = JSON3.read(read("npc_config.json", String), NpcConfig)

path = "Einarr.npc"
doc = NPCTeX.parsefile(path, config)

JSON3.write("tempFile.json", doc);
data = read("tempFile.json", String)
rm("tempFile.json")

refData = read("test_data_einarr.json", String)
@test (data == refData)