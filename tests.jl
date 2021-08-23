using Revise
using JSON3
using Test
Revise.includet("NPCTeX.jl");
using .NPCTeX

function filify(dataIn)
    JSON3.write("tempFile.json", dataIn);
    dataOut = read("tempFile.json", String);
    rm("tempFile.json");
    return dataOut
end

config = read_config("npc_config.json")

refData = read("test_data_einarr.json", String);

path = "Einarr.npc";
doc = parsefile(path, config);
@test (refData == filify(parsefile(path, config)))