using Revise
using JSON3
using Test
Revise.includet("src/NPCTeX.jl");
using .NPCTeX

docSettingsRef = JSON3.read(read("json/test_data_document_settings.json", String), DocumentSettings);
mappingsRef = JSON3.read(read("json/test_data_mappings.json", String), Vector{MappingStrict});
docRef = JSON3.read(read("json/test_data_einarr.json", String), Document);

path = "npc/Einarr_test.npc"
config = NpcConfig("json/npc_config.json");
doc = parsefile(path, config);

@test docSettingsRef == config.documentSettings
@test mappingsRef == config.mappings
@test docRef == doc

# JSON3.write("json/test_data_document_settings.json", docSettings) # to save new reference data
# JSON3.write("json/test_data_mappings.json", mappings) # to save new reference data
# JSON3.write("json/test_data_einarr.json", parsefile(path, docSettings, mappings)) # to save new reference data

