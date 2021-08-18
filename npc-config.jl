using JSON3

mutable struct Atom
    key::String
    value::String
end

mutable struct Element
    atoms::Vector{Atom}
    mapping::Mapping
end

mutable struct Document
    elements::Vector{Element}
end

const Match = Union{String, Vector{String}}

struct LatexCommand
    command::String
    nInputs::Int64
    LatexCommand(command, nInputs) = 
        new(command, isnothing(nInputs) ? 1 : nInputs )
end

struct Mapping
    description::String
    matchList::Union{Vector{Match},Nothing}
    latex::LatexCommand
    includeInputs:: Vector{Bool}    
    paddingChars::Vector{String}
    isTable::Bool
    separators::Vector{String}
    Mapping(description, matchList, latex, includeInputs, paddingChars, isTable, separators) = new(
        isnothing(description) ? "1" : description,
        matchList, 
        latex,
        isnothing(includeInputs) ? String[] : includeInputs, 
        isnothing(paddingChars) ? Bool[] : paddingChars, 
        isnothing(isTable) ? false : isTable, 
        isnothing(separators) ? String[] : separators)
end


struct NpcConfig
    commentChar::Vector{String}
    tableRowChar::Vector{String}
    concatenators::Vector{String}
    mappings::Vector{Mapping}
end

JSON3.StructType(::Type{<:NpcConfig}) = JSON3.Struct()
JSON3.StructType(::Type{<:Mapping}) = JSON3.Struct()
JSON3.StructType(::Type{<:LatexCommand}) = JSON3.Struct()

aap = JSON3.read(read("./npc-config.json", String), NpcConfig)
aap.concatenators
aap.mappings[25]