# using Revise 
# using JSON3
# includet("src/npc-interfaces.jl");
# includet("src/npc-json.jl");
# includet("src/npc-map.jl");
# includet("src/npc-parse.jl");

include("src/NPCTeX.jl");
using .NPCTeX

config = NpcConfig("json/npc_config_full.json");
doc = parsefile("npc/Ludovico_zanni_lvl_01.npc", config);
write_file("tex/Ludo.tex", doc, config)

