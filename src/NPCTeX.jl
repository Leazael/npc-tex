module NPCTeX

using JSON3
export NpcConfig, Document, Mapping, MappingStrict, DocumentSettings, LatexCommand, Concatenator, Element, Atom, Document, parsefile, write_file, parse_to_file

include("npc-interfaces.jl")
include("npc-parse.jl")
include("npc-map.jl")
include("npc-json.jl")

end