using Revise
using JSON3
using Test
Revise.includet("NPCTeX.jl");
using .NPCTeX

JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()
JSON3.StructType(::Type{<:Concatenator}) = JSON3.Struct()
JSON3.StructType(::Type{<:Atom}) = JSON3.Struct()
JSON3.StructType(::Type{<:Element}) = JSON3.Struct()
JSON3.StructType(::Type{<:Document}) = JSON3.Struct()

function filify(dataIn)
    JSON3.write("tempFile.json", dataIn);
    dataOut = read("tempFile.json", String);
    rm("tempFile.json");
    return dataOut
end

config = JSON3.read(read("npc_config.json", String), NpcConfig)

refData = read("test_data_einarr.json", String);

path = "Einarr.npc";
doc = parsefile(path, config);
@test (refData == filify(parsefile(path, config)))