const Match = Union{String, Vector{String}}

struct Concatenator
    match::String 
    remove::Bool
    addWhitespace::Bool
end

struct LatexCommand
    command::String
    nInputs::Int64
    LatexCommand(command, nInputs) = 
        new(command, isnothing(nInputs) ? 1 : nInputs )
end

struct Mapping
    description::String
    matchList::Union{Vector{Match}, Nothing}
    latex::LatexCommand
    includeInputs:: Vector{Bool}    
    paddingChars::Vector{String}
    isTable::Bool
    separators::Vector{String}
    Mapping(description, matchList, latex, includeInputs, paddingChars, isTable, separators) = new(
        isnothing(description) ? "" : description,
        isnothing(matchList) ? String[] : [isa(m,String) ? [m] : m  for m in matchList],
        latex,
        isnothing(includeInputs) ? String[] : includeInputs, 
        isnothing(paddingChars) ? Bool[] : paddingChars, 
        isnothing(isTable) ? false : isTable, 
        isnothing(separators) ? String[] : separators)
end


struct NpcConfig
    commentChar::Vector{String}
    tableRowChar::Vector{String}
    concatenators::Vector{Concatenator}
    mappings::Vector{Mapping}
end


mutable struct Atom
    key::String
    value::String
end
Base.isempty(a::Atom) = isempty(a.key * a.value)

mutable struct Element
    atoms::Vector{Atom}
    mapping::Union{Mapping, Nothing}
end
Element() = Element(Atom[], nothing)


mutable struct Document
    elements::Vector{Element}
end