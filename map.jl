using Revise
using JSON3
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

docSettings, mappings = read_and_simplify("json/npc_config_ext.json");
doc = parsefile("npc/Einarr_extended.npc", docSettings, mappings);
write("tex/Einarr2.tex", doc, docSettings)
