local ipairs = ipairs
local log = require("app.core.log")
local core_table = require("app.core.table")
local lrucache = require("app.core.lrucache")
local radixtree = require("resty.radixtree")
local cjson = require("cjson")
local tostring = tostring
local _M = {}

local radix_cache
local rx_key = "rbac.rx"

do
    radix_cache = lrucache.new({ count = 2048 })
end -- end do

local function create_rx(rbac_data)
    local mapping = {}
    for _, data in ipairs(rbac_data) do
        core_table.insert(mapping,
            {
                paths = { data.key },
                metadata = data.rules,
            })
    end
    --    log.error("mapping: ", json.delay_encode(mapping))
    return radixtree.new(mapping)
end


-- 匹配权限
function _M.match(app_code, url, user_id, method)
    local rx = radix_cache:get(rx_key, false)
    --    local rule = rx:match(url)
    local match_method_uri = core_table.concat({ '/', app_code, '/', method, url })
    --    log.error("match_method_uri: ", match_method_uri)
    local rule = rx:match(match_method_uri)
    if not rule then
        local match_all_uri = core_table.concat({ '/', app_code, '/', 'ALL', url })
        log.error("match_all_uri: ", match_all_uri)
        rule = rx:match(match_all_uri)
    end
    --    local user_id_method = core_table.concat({ app_code, '|', method, '|', user_id }) -- mg|GET|1
    --    local user_id_all_method = core_table.concat({ app_code, '|', 'ALL', '|', user_id })
    --    log.error("mapping: ", user_id_method, rule[user_id_method])
    --    log.error("rule: ", user_id, type(user_id))
    --    user_id = tostring(user_id)
    local user_id_str = tostring(user_id)
    if rule and rule[user_id_str] == "y" then
        --        log.error("rule: ", cjson.encode(rule))
        return true
    else
        return false
    end
end


-- 注册URI权限
function _M.refresh(rbac_data)
    local rx = create_rx(rbac_data)
    radix_cache:set(rx_key, rx)
end

return _M
