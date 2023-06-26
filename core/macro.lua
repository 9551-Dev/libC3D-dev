local parse   = require("common.parser_util")
local strutil = require("common.string_util")
local generic = require("common.generic")

local object = require("core.object")

local tampl = require("lib.tampl")

return function(c3d)
    local null_injection = tampl.compile_code("NULL")

    local macro_util_object = {
        __index=object.new{
            tampl       =tampl,
            compile     =tampl.compile_code,
            make_varname=function(self,name)
                return ("%s_macro_%s_%s"):format(name,self.name,self.macro_id)
            end,
            wrap_doend=function(self,str)
                return ("do\n%s\nend"):format(str)
            end,
            stitch=function(...)
                local data = {...}
                return table.concat(data,"\n")
            end 
        },
    __tostring=function(self) return "MACRO_UTIL"..strutil.format_table__tostring(self) end}

    local function generate_macro_identity(name,index,for_processor)
        return (for_processor and "" or "_") .. ("c3d_macro_%s<%d>"):format(name,index)
    end

    local function process_macros(macro_source,macros)

        local macro_injections = {}
        for key,macro in pairs(macros) do
            local name      = macro.type
            local processor = macro.processor

            local macro_presence = 0

            macro_injections[name] = {
                name       = name,
                processor  = processor,
                keep_hooks = macro.keep_hooks,
                list       = {},
                macro_id   = generic.macro_id()
            }

            macro_source = macro_source:gsub("([%w_%.:]+%(.-%))",function(match)
                local macro_name,arguments = parse.function_call(match)
                if macro_name == name then
                    macro_presence = macro_presence + 1

                    macro_injections[name].list[macro_presence] = arguments

                    return ("--[[#%s]]"):format(generate_macro_identity(macro_name,macro_presence,true))
                end
            end)

            macro_injections[name].count = macro_presence
        end

        local macro_patchable = tampl.new_patch(macro_source)
        for name,macro in pairs(macro_injections) do
            local dedicated_utils = setmetatable(macro,macro_util_object):__build()
            for macro_index=1,macro.count do
                local arguments = macro.list[macro_index]

                local macro_hook = macro_patchable[generate_macro_identity(name,macro_index)]

                macro_patchable.inject(macro_hook,tampl.At("HEAD"),macro.processor(dedicated_utils,table.unpack(arguments)))
                if not macro.keep_hooks then
                    macro_patchable.inject(macro_hook,tampl.At("WIPE"),null_injection)
                end
            end
        end

        return macro_patchable.apply_patches(),macro_patchable
    end

    --[==[local macro_source = [=[
        local tbl = {}
        write("hello world")
        addtable(tbl,1,2,3,4,5)
        for i=1,5 do
            printat(tbl[i],1,i+1)
        end
    ]=]

    local function write_macro_processor(util,a1)
        return util.compile(([[
            term.write(%s)
        ]]):format(a1))
    end

    local function printat_macro_processor(util,text,x,y)
        return util.compile(([[
            term.setCursorPos(%s,%s)
            print(%s)
        ]]):format(x,y,text))
    end

    local function addtable_macro_processor(util,name,...)
        local count_var = util:make_varname("index")
        local code = ("local %s=1"):format(count_var)
        local args = {...}
        for i=1,#args do
            local value = args[i]
            code = code .. util.stitch(
                ("%s[%s] = %s"):format(name,count_var,value),
                ("%s = %s + 1"):format(count_var,count_var)
            )
        end

        return util.compile(util:wrap_doend(code))
    end

    local built = process_macros(macro_source,{
        {
            processor=write_macro_processor,
            type="write"
        },
        {
            processor=printat_macro_processor,
            type="printat"
        },
        {
            processor=addtable_macro_processor,
            type="addtable"
        }
})

    c3d.log.add(built)]==]

    return {
        process=process_macros
    }

end