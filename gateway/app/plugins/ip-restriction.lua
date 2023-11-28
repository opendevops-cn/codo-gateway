--
-- Created by IntelliJ IDEA.
-- User: shenshuo
-- Date: 2021/6/9
-- Time: 15:22
-- To change this template use File | Settings | File Templates.
--

local ngx = ngx
local resp = require("app.core.response")
local core = require("app.core")
local ipmatcher = require("resty.ipmatcher")
local str_utils = require("app.utils.str_utils")

local lrucache = core.lrucache2.new({
    ttl = 300,
    count = 512
})

local plugin_name = "ip-restriction"

local _M = {
    priority = 3000, -- TODO: add a type field, may be a good idea
    name = plugin_name,
    desc = "IP黑白名单",
    optional = true,
    version = "v0.1"
}


local function create_ip_matcher(ip_list)
    local ip, err = ipmatcher.new(ip_list)
    if not ip then
        core.log.error("failed to create ip matcher: ", err, " ip list: ", core.json.delay_encode(ip_list))
        return nil
    end

    return ip
end


function _M.do_in_access(route)
    local block = false
    -- local remote_addr = ngx.var.remote_addr
    local remote_addr = str_utils.split(ngx.var.proxy_add_x_forwarded_for, ',')[1]
    local blacklist = route.props.ip_blacklist
    local whitelist = route.props.ip_whitelist
    --    ngx.log(ngx.ERR, 'remote_addr--->>>>>>>>>>>>>', remote_addr)
    if blacklist and #blacklist > 0 then
        local matcher = lrucache(blacklist, nil, create_ip_matcher, blacklist)
        if matcher then
            block = matcher:match(remote_addr)
        end
    end

    if whitelist and #whitelist > 0 then
        local matcher = lrucache(whitelist, nil, create_ip_matcher, whitelist)
        if matcher then
            block = not matcher:match(remote_addr)
        end
    end

    if block then
        return resp.exit(ngx.HTTP_FORBIDDEN)
    end
end


return _M

