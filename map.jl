using Revise
using JSON3
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

config = JSON3.read(read("json/npc_config.json", String), NpcConfig);
doc = parsefile("npc/Einarr_extended.npc", config);
write("tex/Einarr2.tex", doc, config)