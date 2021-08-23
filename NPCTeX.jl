module NPCTeX

using Revise
using JSON3

export NpcConfig, Mapping, LatexCommand, Concatenator, Element, Atom, Document, parsefile, read_config, map_element, write

includet("npc-interfaces.jl")
includet("npc-parse.jl")
includet("npc-map.jl")
includet("npc-json.jl")

end