using Revise
using JSON3
using Test
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

function filify(dataIn)
    JSON3.write("tempFile.json", dataIn);
    dataOut = read("tempFile.json", String);
    rm("tempFile.json");
    return dataOut
end

config = read_config("json/npc_config.json");
refData = read("json/test_data_einarr.json", String);

path = "npc/Einarr.npc";
doc = parsefile(path, config);
@test (refData == filify(parsefile(path, config)))