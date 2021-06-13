module NPCTeX

export load_and_clean, parse_npc, write_npc, parse_file

enbracket(ss...) = *(["{" * strip(s) * "}" for s in ss]...)

function caputure_and_clean_keywords(rr::Regex, ss::AbstractString)
    m = match(rr, ss)
    return [strip(strip(strip(s), [':',',',';'])) for s in m.captures]
end

caputure_and_clean_keywords(rr::Vector{String}, ss::AbstractString) = caputure_and_clean_keywords(Regex(join(["!" * lowercase(r) * "(.*)" for r in rr]), "i"), ss)

is_comma(s::AbstractString) = endswith(s, ",")
is_ellipsis(s::AbstractString) = endswith(s, "...")
is_tabular(s::AbstractString) = startswith(s, ">")

pull_keywords(ss::String) = [lowercase(m.match[2:end]) for m in eachmatch(r"![\w]*",ss)]

# //Comments.
# , at end line... same
# ... continue line
# > line belongs as a tabular entry to above line.

# ===divider 
is_divider(ss::String) = length(ss)>3 && ss[1:3] == "==="
parse_divider(ss::String) = "\\divider" * enbracket(strip(strip(ss),'='))
# ss = "===Defence==="

# :Plain text is whats going on
is_plain_text(ss::String) = ss[1] == ':'
parse_plain_text(ss::String) = "\\plain" * enbracket(ss[2:end])
# ss = ":Human Inquisitor [Preacher / Urban Infiltrator] 6"

is_indent_plain(ss::String) = strip(ss)[1] == ':' && ss[1] !==':'
parse_indent_plain(ss::String) = "\\indentplain" * enbracket(strip(ss)[2:end])
# ss = "    :This is a note..

# _following line is a remark
is_remark(ss::String) = ss[1] == '~'
parse_remark(ss::String) = "\\remark" * enbracket(ss[2:end])
# ss = "~As a swift or immediate action gain the noted effect.

is_indent_remark(ss::String) = strip(ss)[1] == '~' && ss[1] !=='~'
parse_indent_remark(ss::String) = "\\indentremark" * enbracket(strip(ss)[2:end])
# ss = "    ~This is a note..

# #basicability: stuff
is_basic_ability(ss::String) = occursin(r"#[\sa-zA-Z]*\:",ss)
parse_basic_ability(ss::String) = "\\basicability" * enbracket(match(r"#([\sa-zA-Z]*):(.*)", ss).captures...)
# ss = "#Special Defenses: Determination (3/day +4 AC, immediate action)"

# %listing: stuff
is_listing(ss::String) = occursin(r"%[\sa-zA-Z]*\:",ss)
parse_listing(ss::String) = "\\listing" * enbracket(match(r"%([\sa-zA-Z]*):(.*)", ss).captures...)
# ss = "%Languages: Ilms II, Angels II, Sosulkan II, Draconic II"

# @ability [su] (how often) Description
is_ability(ss::String) = occursin(r"@[\s\w]*\[[\s\w]*\]\s*\([\s\w/]*\)",ss)
parse_ability(ss) = "\\ability" * enbracket(match(r"@([\s\w]*)\[([\s\w]*)\]\s*\(([\s\w/]*)\)(.*)", ss).captures...)
# ss = "@Powerful bond [Su] (7/day) Create a telepathic link with an ally within 60 ft. Must share language."

# @continuous ability [su] Description
is_continuous_ability(ss::String) = occursin(r"@[\s\w]*\[[\s\w]*\]",ss) && !is_ability(ss)
parse_continuous_ability(ss::String) = "\\continuousability" * enbracket(match(r"@([\s\w]*)\[([\s\w]*)\](.*)",ss).captures...)
# ss = "@Detect Alignment[Sp] Detect Alignment at will"

# $Spell Known (iets) -- Lijst
is_spell_known(ss::String) = occursin("--", ss) && ss[1] == '$' && occursin(r"\(.+\)", split(ss,"--")[1]) 
parse_spell_known(ss::String) = "\\spellsknown" * enbracket(match(r"\$(.*)\((.*)\)\s*--(.*)",ss).captures...)
# ss = "\$1st (4/day) -- Cure Light Wounds, ???"

# $Spell Ready -- Lijst
is_spell_ready(ss::String) = occursin("--", ss) && ss[1] == '$' && !occursin(r"\(.+\)", split(ss,"--")[1]) 
parse_spell_ready(ss::String) = "\\spellsready" * enbracket(match(r"\$(.*)--(.*)",ss).captures...)
# ss = "\$Orisons -- Create Water, Detect Magic, Detect Poison, Guidance, Light, Stabilize"

# !keyword they are case insensitive, more than one may occur
is_keyword_struct(ss::String) = occursin(r"![a-zA-Z]*",ss) && !occursin(">>",ss)
function parse_keyword_struct(ss::String)
    keywords = pull_keywords(ss)
    parsed = enbracket(caputure_and_clean_keywords(keywords, ss)...);
    if keywords == ["str", "dex", "con", "int", "wis", "cha"]
        return "\\abilityscores" * parsed
    elseif keywords == ["init", "senses"]
        return "\\initsense" * parsed
    elseif keywords == ["name"]
        return "\\name" * parsed
    elseif keywords == ["ac", "touch", "flatfooted"]
        return "\\ac" * parsed
    elseif keywords == ["hp"]
        return "\\stat{hp}" * parsed
    elseif keywords == ["vp", "wp"]
        return "\\vpwp" * parsed
    elseif keywords == ["vp", "wp", "dr"]
        return "\\vpwpdr" * parsed
    elseif keywords == ["vp", "wp", "fasthealing", "dr"]
        return "\\vpwpfhdr" * parsed
    elseif keywords == [ "fasthealing", "dr"]
        return "\\fhdr" * parsed
    elseif keywords == ["fort", "ref", "will"]
        return "\\saves" * parsed
    elseif keywords == ["speed"]
        return "\\stat{Speed}" * parsed
    elseif keywords == ["bab", "cmb", "cmd"]
        return "\\babs" * parsed
    elseif keywords == ["feats"]
        return "\\listing{Feats}" * parsed
    elseif keywords == ["skills"]
        return "\\listing{Skills}" * parsed
    elseif keywords == ["resist"]
        return "\\stat{Resist}" * parsed
    elseif keywords == ["immune"]
        return "\\stat{Immune}" * parsed
    elseif keywords == ["resist", "immune"]
        return "\\resistimmune" * parsed
    elseif keywords == ["melee"]
        return "\\stat{Melee}" * parsed
    elseif keywords == ["ranged"]
        return "\\stat{Ranged}" * parsed
    else
        println("\"" * ss * "\" is not a recognized keyword structure")
        return "error: unknown keyword structure"
    end
end
# ss = "!Init +10 !Senses: Detect Alignment, Preception +13"
# data0[is_keyword_struct.(data0)]

is_keyword_tab(ss::String) = occursin(r"![a-zA-Z]*",ss) && occursin(">>",ss)
function parse_keyword_tab(ss::String)
    keywords = pull_keywords(ss)
    if keywords == ["melee"] || keywords == ["ranged"]
        type = uppercasefirst(keywords[1])
        preparsed = split(caputure_and_clean_keywords(keywords, ss)[1], ">>")
        header = preparsed[1]
        body = join([replace(s, '|' => '&') for s in preparsed[2:end]], "\\\\")
        return "\\begin{attackgroup}" * enbracket(type, header) * "\n"  * body * "\n" * "\\end{attackgroup}"
    else
        println("tabular keywords in \"" * ss * "\" not recognized")
        return "error: unknown tabular"
    end
end
# data0[is_keyword_tab.(data0)]
# \begin{attackgroup}{Ranged}{mwk Revolver (20 ft., misfire 1)}
#     Normal  & +3 & (1d8 / ×4) \\
#     Bane    & +7 & (1d8 + 2d6 / ×4)
# \end{attackgroup}


function is_well_defined(ss::String)
    defTuple = (is_divider(ss), is_plain_text(ss), is_indent_plain(ss), is_remark(ss), 
        is_indent_remark(ss),is_keyword_struct(ss), is_keyword_tab(ss), 
        is_basic_ability(ss), is_continuous_ability(ss), is_listing(ss),
        is_ability(ss), is_spell_known(ss), is_spell_ready(ss) )
    return sum(defTuple) .== 1
end

function load_and_clean(fileLoc::AbstractString)
    # load data and clean up on the right
    f = open(fileLoc, "r")
    data = rstrip.(readlines(f));
    close(f)

    # remove empty or comment realted lines
    data = data[.!isempty.(data)]
    data = data[[l[1:2] != "//" for l in data]]

    newData = [popfirst!(data)];
    while ~isempty(data)
        ll = popfirst!(data);
        if is_comma(newData[end]) # if the previous line ended with a comma, append
            newData[end] = rstrip(newData[end]) * " " * lstrip(ll)
        elseif is_ellipsis(newData[end]) # if the previous line ended with an ellipsis, append
            newData[end] = newData[end][1:end-3]
            newData[end] = rstrip(newData[end]) * " " * lstrip(ll)
        elseif is_tabular(ll) # if the current line is tabular, append
            newData[end] = rstrip(newData[end]) * " >> " * lstrip(ll[2:end]) 
        else # otherwis, push
            push!(newData, ll)
        end
    end
    newData = String.(newData);
    
    for ss in newData
        @assert(is_well_defined(ss), "\"" *  ss * "\" is not well defined.")
        @assert(!occursin("{", ss) && !occursin("}", ss) , "\"" *  ss * "\" may not contain curly brackets.")
    end

    return newData
end

function write_npc(fileName::AbstractString, data::Vector{String})
    open(fileName, "w") do io
        for ss in data
            println(io, ss)
            println(io, "")
        end
    end
end

function parse_npc(ss::String)
    if is_keyword_struct(ss)
        return parse_keyword_struct(ss)
    elseif is_keyword_tab(ss)
        return parse_keyword_tab(ss)
    elseif is_divider(ss)
        return parse_divider(ss)
    elseif is_plain_text(ss)
        return parse_plain_text(ss)
    elseif is_indent_plain(ss)
        return parse_indent_plain(ss)
    elseif is_remark(ss)
        return parse_remark(ss)
    elseif is_indent_remark(ss)
        return parse_indent_remark(ss)
    elseif is_basic_ability(ss)
        return parse_basic_ability(ss)
    elseif is_continuous_ability(ss)
        return parse_continuous_ability(ss)
    elseif is_listing(ss)
        return parse_listing(ss)
    elseif is_ability(ss)
        return parse_ability(ss)
    elseif is_spell_known(ss)
        return parse_spell_known(ss)
    elseif is_spell_ready(ss)
        return parse_spell_ready(ss)
    else
        error("\"" *  ss * "\" could not be parsed." )
    end
end

function parse_file(fileName::AbstractString)
    data0 = load_and_clean(fileName);
    data1 = parse_npc.(data0);
    outFile = fileName[1:end-3] * "tex"

    write_npc(outFile, data1);
end

function parse_file(fileName::AbstractString, outFile::AbstractString)
    data0 = load_and_clean(fileName);
    data1 = parse_npc.(data0);
    write_npc(outFile, data1);
end

end
