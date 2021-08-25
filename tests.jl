using Revise
using JSON3
using Test
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

docSettings, mappings = read_and_simplify("json/npc_config.json") 
doc = parsefile("npc/Einarr_test.npc", docSettings, mappings);
# JSON3.write("json/test_data_einarr.json", doc) # to save new reference data

docRef = JSON3.read(read("json/test_data_einarr.json", String), Document)
@test(doc.elements == docRef.elements)