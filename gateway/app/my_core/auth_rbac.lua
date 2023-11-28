local ipairs = ipairs
local log = require("app.core.log")
local core_table = require("app.core.table")
local lrucache = require("app.core.lrucache")
local radixtree = require("resty.radixtree")
local cjson = require("cjson")
local json = require("app.core.json")
local tostring = tostring
local _M = {}

local radix_cache
local rx_key = "auth.rx"
local rbac_prefix = "/my/gw/authrbac"

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
    --log.error("mapping: ", json.delay_encode(mapping))
    return radixtree.new(mapping)
end


-- 匹配权限
function _M.match(app_code, url, user_id, method)
    local rx = radix_cache:get(rx_key, false)
    --    local rule = rx:match(url)

    local match_method_uri = core_table.concat({ rbac_prefix, '/', app_code, '/', method, url })

    log.error("match_method_uri=========>>>>>: ", match_method_uri)

    local rule = rx:match(match_method_uri)

    if not rule then
        log.error("can not match uri : ", match_method_uri)
        return false
    end

    local user_id_str = tostring(user_id)
    log.error("user_id_str: ", user_id_str)

    if rule and rule[user_id_str] == "y" then
        log.error("rule: ", cjson.encode(rule))
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
