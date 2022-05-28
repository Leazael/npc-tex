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
Base.:(==)(m1::MappingStrict, m2::MappingStrict)::Bool =  all([getproperty(m1,p) == getproperty(m2,p) for p in propertynames(m1)])

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


struct DocumentSettings
    commentChar::Vector{String}
    tableRowChar::Vector{String}
    concatenators::Vector{Concatenator}
end
Base.:(==)(obj1::DocumentSettings, obj2::DocumentSettings)::Bool =  all([getproperty(obj1,p) == getproperty(obj2,p) for p in propertynames(obj1)])

struct NpcConfigJSON
    documentSettings::DocumentSettings
    mappings::Vector{Mapping}
end

struct NpcConfig
    documentSettings::DocumentSettings
    mappings::Vector{MappingStrict}
end


mutable struct Atom
    key::String
    value::String
end
Atom(s::Union{AbstractString, Char}) = Atom(string(s), "")
Base.:(==)(a1::Atom, a2::Atom)::Bool = (a1.key == a2.key) && (a1.value == a2.value)


mutable struct Element
    atoms::Vector{Atom}
    mapping::MappingStrict
end
Element(m::MappingStrict) = Element([Atom("", "")], m)
Base.:(==)(e1::Element, e2::Element)::Bool = (e1.atoms == e2.atoms) &&  (e1.mapping == e2.mapping)


mutable struct Document
    elements::Vector{Element}
end
Base.:(==)(d1::Document, d2::Document)::Bool = d1.elements == d2.elements


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


function restrict_matchlist(m::Mapping, ml::Vector{String})::MappingStrict
    @assert( ( isnothing(m.matchList) && isempty(ml) ) || (length(m.matchList) == length(ml)), "Length of new matchlist does not equal length of old matchlist" )

    if !isnothing(m.matchList)
        for k=1:length(ml)
            @assert(ml[k] == m.matchList[k] || ml[k] in m.matchList[k], ml[k] * " not found in current matchist: " * string(m.matchList[k]))
        end
    end
    return MappingStrict(m.description, ml, m.latex, m.includeInputs, m.paddingChars, m.isTable, m.separators)    
end

function simplify(mping::Mapping)::Vector{MappingStrict}
    nMatches = isnothing(mping.matchList) ? 0 : length(mping.matchList)
    expandedMatchList = [ String[] ]

    for k=1:nMatches
        cMatch = mping.matchList[k]
        if isa(cMatch, String)
            expandedMatchList = [ [ml; cMatch] for ml in expandedMatchList]
        else
            expandedMatchList = [ [ml;m] for ml in expandedMatchList, m in cMatch][:]
        end
    end
    
    return [restrict_matchlist(mping, ml) for ml in expandedMatchList]
end


function simplify(mm::Vector{Mapping})::Vector{MappingStrict}
    mmStrict = MappingStrict[]
    for m in mm
        append!(mmStrict, simplify(m))
    end
    return mmStrict
end

istrivial(a::Atom) = isempty(a.key * a.value)
istrivial(elem::Element) = all(istrivial.(elem.atoms))
istrivial(elems::Vector{Element}) = all(istrivial.(elems))
keys(elem::Element) = [a.key for a in elem.atoms]
Document() = Document(Element[])
Base.push!(doc::Document, elem::Element) = push!(doc.elements, elem)