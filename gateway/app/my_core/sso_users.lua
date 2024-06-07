local ipairs = ipairs
local log = require("app.core.log")
local json = require("app.core.json")
local core_table = require("app.core.table")
local lrucache = require("app.core.lrucache")
local radixtree = require("resty.radixtree")
local _M = {}

local radix_cache
local rx_key = "sso_users.rx"

do
    radix_cache = lrucache.new({ count = 2048 })
end -- end do

local function create_rx(sso_users_list)
    log.debug("[create_rx] sso_users_list ", json.delay_encode(sso_users_list, false))
    local mapping = {}
    for _, data in ipairs(sso_users_list) do
        core_table.insert(mapping,
            {
                paths = { data.email },
                metadata = data,
            })
    end
    --    log.error("mapping: ", json.delay_encode(mapping))
    return radixtree.new(mapping)
end


-- 匹配权限
function _M.get_user(email)
    local rx = radix_cache:get(rx_key, false)
    local user_info = rx:match(email)
    return user_info
end


-- 注册URI权限
function _M.refresh(sso_users_list)
    local rx = create_rx(sso_users_list)
    radix_cache:set(rx_key, rx)
end

return _M
