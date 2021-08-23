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

function append_value!(a::Atom, s::AbstractString)
    if isempty(a.value) || (isspace(last(a.value)) && isspace(first(s)))
        a.value = a.value * lstrip(s)
    else
        a.value = a.value * s
    end
end

function append_key!(a::Atom, s::String)
    @assert(!any([isspace(c) for c in s]))
    a.key = a.key * s
end


mutable struct Element
    atoms::Vector{Atom}
    mapping::Union{Mapping, Nothing}
end
Element() = Element(Atom[], nothing)
istrivial(elem::Element) = all(isempty.(elem.atoms))
keys(elem::Element) = [a.key for a in elem.atoms]

function iscomplete(elem::Element)::Bool
    keyList = keys(elem)
    matchList = elem.mapping.matchList
    if length(keyList) != length(matchList)
        return false
    end

    for k=1:length(keyList)
        if isa(matchList[k],String)
            if lowercase(keyList[k]) != lowercase(matchList[k])
                return false 
            end
        else
            if !(lowercase(keyList[k]) in lowercase.(matchList[k]))
                return false 
            end
        end
    end

    return true
end

function yield_first(elementList::Vector{Element})::Element
    index = findfirst(iscomplete, elementList)
    if isnothing(index)
        error("No complete elements found in list: ", elementList)
    else
        return elementList[index]
    end
end


mutable struct Document
    elements::Vector{Element}
end