using Revise
using JSON3
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

config = NpcConfig("json/npc_config_full.json")
doc = parsefile("npc/Ludovico_zanni.npc", config);
write_file("tex/Ludo.tex", doc, config)

