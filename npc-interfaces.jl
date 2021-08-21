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
function append_value!(a::Atom, buffer::String, c::Char)
    if isempty(a.value) || (isspace(last(a.value)) && isspace(first(buffer * c)))
        a.value = a.value * lstrip(buffer * c)
    else
        a.value = a.value * buffer * c
    end
end

function append_key!(a::Atom, buffer::String, c::Char)
    if !isspace(c)
        a.key = a.key * buffer * c
    end
end


mutable struct Element
    atoms::Vector{Atom}
    mapping::Union{Mapping, Nothing}
end
Element() = Element(Atom[], nothing)
istrivial(el::Element) = all(isempty.(el.atoms))

mutable struct Document
    elements::Vector{Element}
end