using Revise
using JSON3
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

config = read_config("json/npc_config_ext.json")
doc = parsefile("npc/Einarr_extended.npc", config);
write("tex/Einarr2.tex", doc, config)
