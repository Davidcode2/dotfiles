local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet

require("luasnip.loaders.from_snipmate").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load()

ls.add_snippets("markdown", {
  s("post_layout", {
    t({ "---", "" }),
    t({ "title: "}),
    i(0),
    t({ "", "date: "}),
    t(os.date("%Y-%m-%d")),
    t({ "", "tags: post", "" }),
    t({ "layout: post-layout.njk" ,"" }),
    t({ "---" })
  })
})

ls.add_snippets("markdown", {
  s("plantuml", {
    t({ "```plantuml", "" }),
    t({ "@startuml"}),
    t({ "", ""}),
    i(0),
    t({ "", ""}),
    t({ "", "@enduml", "" }),
    t({ "```" , "" })
  })
})

ls.add_snippets("markdown", {
  s("c4plantuml", {
    t({ "```plantuml", "" }),
    t({ "@startuml", "" }),
    t({ "!include  https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml", ""}),
    i(0),
    t({ "", ""}),
    t({ "", "@enduml", "" }),
    t({ "```" , "" })
  })
})
