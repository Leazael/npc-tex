include("src/NPCTeX.jl");
using .NPCTeX
using JSON3
using Test

docSettingsRef = JSON3.read(read("json/test_data_document_settings.json", String), DocumentSettings);
mappingsRef = JSON3.read(read("json/test_data_mappings.json", String), Vector{MappingStrict});
docRef = JSON3.read(read("json/test_data_einarr.json", String), Document);

path = "npc/Einarr_test.npc"
config = NpcConfig("json/npc_config.json");
doc = parsefile(path, config);

@test docSettingsRef == config.documentSettings;
@test mappingsRef == config.mappings;
@test isequal(docRef, doc);

# JSON3.write("json/test_data_document_settings.json", config.documentSettings) # to save new reference data
# JSON3.write("json/test_data_mappings.json", config.mappings) # to save new reference data
# JSON3.write("json/test_data_einarr.json", parsefile(path, docSettings, mappings)) # to save new reference data