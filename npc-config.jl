using JSON3
using StructTypes

mutable struct LatexCommand
    command::String
    nInputs::Int64
    LatexCommand() = new("", 1)
end

mutable struct Keyword
    matchList::Vector{Any}
    latex::LatexCommand
    isTable::Bool
    separators::Vector{String}
    Keyword() = new(Any[], LatexCommand(), false, String[])
end

mutable struct NpcConfig
    commentChar::Vector{String}
    tableRowChar::Vector{String}
    keywordChar::Vector{String}
    concatenators::Vector{String}
    keywords::Vector{Keyword}
    environments::Any
    NpcConfig() = new()
end

JSON3.StructType(::Type{<:NpcConfig}) = StructTypes.Mutable()
JSON3.StructType(::Type{<:Keyword}) = StructTypes.Mutable()
JSON3.StructType(::Type{<:LatexCommand}) = StructTypes.Mutable()

aap = JSON3.read(read("./npc-config.json", String), NpcConfig)
aap.concatenators
aap.keywords