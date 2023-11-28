--
-- Created by IntelliJ IDEA.
-- User: shenshuo
-- Date: 2021/6/1
-- Time: 16:17
-- To change this template use File | Settings | File Templates.
--
local resp = require("app.core.response")
local core = require("app.core")
--local json = require("app.core.json")
local http = require "resty.http"
local ipairs = ipairs
local ngx = ngx

local lrucache = core.lrucache2.new({
    ttl = 300,
    count = 64
})


local plugin_name = "referer-restriction"

local _M = {
    name = plugin_name,
    priority = 180,
    desc = "Referer请求头限制",
    optional = true,
    version = "v0.1"
}

local function match_host(matcher, host)
    if matcher.map[host] then
        return true
    end
    for _, h in ipairs(matcher.suffixes) do
        if core.string.has_suffix(host, h) then
            return true
        end
    end
    return false
end


local function create_host_matcher(hosts)
    local hosts_suffix = {}
    local hosts_map = {}

    for _, h in ipairs(hosts) do
        if h:byte(1) == 42 then -- start with '*'
            core.table.insert(hosts_suffix, h:sub(2))
        else
            hosts_map[h] = true
        end
    end

    return {
        suffixes = hosts_suffix,
        map = hosts_map,
    }
end


function _M.do_in_rewrite(route)
    local var = ngx.var
    local block = false

    local referer = var.http_referer
    local whitelist = route.props.referer_whitelist
    local bypass_missing = route.props.referer_bypass_missing
    --    ngx.log(ngx.ERR, 'referer--->>>>>>>>>>>>>', referer)
    --    ngx.log(ngx.ERR, 'referer_whitelist--->>>>>>>>>>>>>', json.encode(whitelist))
    --    ngx.log(ngx.ERR, 'bypass_missing--->>>>>>>>>>>>>', route.props.bypass_missing)
    if referer then
        local uri = http.parse_uri(nil, referer)
        if not uri then
            referer = nil
        else
            -- take host part only
            referer = uri[2]
        end
    end

    ngx.log(ngx.ERR, 'referer--->>>>>>>>>>>>>', referer)

    if not referer then
        block = not bypass_missing

    elseif whitelist then
        local matcher = lrucache(whitelist, nil, create_host_matcher, whitelist)
        --        ngx.log(ngx.ERR, 'matcher--->>>>>>>>>>>>>', json.encode(matcher))
        block = not match_host(matcher, referer)
    end

    if block then
        return resp.exit(ngx.HTTP_FORBIDDEN)
    end
end

return _M

-- | 参数名    | 类型          | 可选项 | 默认值 | 有效值 | 描述                             |
-- | referer_whitelist | array[string] | 必须    |         |       | 域名列表。域名开头可以用'*'作为通配符 |
-- | referer_bypass_missing    | boolean         | 可选    | false   |     | 当 Referer 不存在或格式有误时，是否绕过检查 |
