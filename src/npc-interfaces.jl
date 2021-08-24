const Match = Union{String,Vector{String}}

struct Concatenator
    match::String 
    remove::Bool
    addWhitespace::Bool
end
Base.length(conc::Concatenator) = length(conc.match)

struct LatexCommand
    command::String
    nInputs::Int64
    LatexCommand(command, nInputs) = 
        new(command, isnothing(nInputs) ? 1 : nInputs)
end

struct MappingStrict
    description::String
    matchList::Vector{String}
    latex::LatexCommand
    includeInputs::Vector{Bool}    
    paddingChars::Vector{String}
    isTable::Bool
    separators::Vector{String}
end


struct Mapping
    description::String
    matchList::Union{Vector{Match},Nothing}
    latex::LatexCommand
    includeInputs::Vector{Bool}    
    paddingChars::Vector{String}
    isTable::Bool
    separators::Vector{String}
    Mapping(description, matchList, latex, includeInputs, paddingChars, isTable, separators) = new(
        isnothing(description) ? "" : description,
        matchList,
        latex,
        isnothing(includeInputs) ? String[] : includeInputs, 
        isnothing(paddingChars) ? Bool[] : paddingChars, 
        isnothing(isTable) ? false : isTable, 
        isnothing(separators) ? String[] : separators)
end


function restrict_matchlist(m::Mapping, ml::Vector{String})::MappingStrict
    @assert( ( isnothing(m.matchList) && isempty(ml) ) || (length(m.matchList) == length(ml)), "Length of new matchlist does not equal length of old matchlist" )
    if !isnothing(m.matchList)
        for k=1:length(ml)
            @assert(ml[k] == m.matchList[k] || ml[k] in m.matchList[k], ml[k] * " not found in current matchist: " * string(m.matchList[k]))
        end
    end
    return MappingStrict(m.description, ml, m.latex, m.includeInputs, m.paddingChars, m.isTable, m.separators)    
end

function expand_and_restrict(mping::Mapping)::Vector{MappingStrict}
    matchList = mping.matchList
    expandedMatchList = [ String[] ]

    if !isnothing(matchList)
        for k=1:length(matchList)
            if isa(matchList[k], String)
                for ml in expandedMatchList
                    push!(ml, matchList[k])
                end
            elseif isa(matchList[k], Vector{String})
                newMatchList = Vector{String}[]
                for m in matchList[k]
                    for ml in expandedMatchList
                        push!(newMatchList, [ml;m])
                    end
                end
                expandedMatchList = newMatchList
            end
        end
    end
    
    return [restrict_matchlist(mping, ml) for ml in expandedMatchList]
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
Atom(s::Union{AbstractString, Char}) = Atom(string(s), "")
istrivial(a::Atom) = isempty(a.key * a.value)

function append_value!(a::Atom, s::AbstractString)
    if isempty(a.value) || (isspace(last(a.value)) && isspace(first(s)))
        a.value = a.value * lstrip(s)
    else
        a.value = a.value * s
    end
end
append_value!(a::Atom, c::Char) = append_value!(a, string(c))

function append_key!(a::Atom, s::String)
    @assert(!any([isspace(c) for c in s]))
    a.key = a.key * s
end
append_key!(a::Atom, c::Char) = append_key!(a, string(c))

mutable struct Element
    atoms::Vector{Atom}
    mapping::Union{Mapping,Nothing}
end
Element(m::Mapping) = Element([Atom("", "")], m)

istrivial(elem::Element) = all(istrivial.(elem.atoms))
istrivial(elems::Vector{Element}) = all(istrivial.(elems))
keys(elem::Element) = [a.key for a in elem.atoms]

function iscomplete(elem::Element)::Bool
    keyList = keys(elem)
    matchList = elem.mapping.matchList

    if isempty(matchList) && length(keyList) == 1 && isempty(keyList[1])
        return true 
    end

    if length(keyList) != length(matchList)
        return false
    end

    for k = 1:length(keyList)
        if isa(matchList[k], String)
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

Document() = Document(Element[])
Base.push!(doc::Document, elem::Element) = push!(doc.elements, elem)