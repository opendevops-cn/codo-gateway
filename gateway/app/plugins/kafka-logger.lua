--
-- Created by IntelliJ IDEA.
-- User: shenshuo
-- Date: 2020/12/25
-- Time: 19:46
-- To change this template use File | Settings | File Templates.
--


local ngx = ngx
local user_info = ngx.shared.user_info
--local resp = require("app.core.response")
--local log = require("app.core.log")
local json = require("app.core.json")
local str_utils = require("app.utils.str_utils")

-- optional 是否可选
local _M = {
    name = "kafka-logger",
    desc = "kafka日志",
    optional = true,
    version = "v0.1"
}


function _M.do_in_log(route)
    -- 记录日志操作
--    local method = ngx.req.get_method()
--    local uri = ngx.var.uri
--    local postargs = ngx.req.get_body_data() --str
--    -- local postargs = ngx.req.get_post_args() --table
--    local data = {
--        username = user_info.username,
--        nickname = user_info.nickname,
--        login_ip = ngx.var.proxy_add_x_forwarded_for,
--        method = method,
--        uri = ngx.var.request_uri,
--        data = postargs,
--        time = os.date('%Y-%m-%d %H:%M:%S')
--    }

    local var = ngx.var
    local client_ip = str_utils.split(ngx.var.proxy_add_x_forwarded_for, ',')[1]
    --    local url = var.scheme .. "://" .. var.host .. ":" .. var.server_port
    --        .. var.request_uri
    local log = {
        request = {
            scheme = ngx.var.scheme,
            uri = ngx.var.request_uri,
            method = ngx.req.get_method(),
            headers = ngx.req.get_headers(),
            querystring = ngx.req.get_uri_args(),
            size = ngx.var.request_length,
            data = ngx.req.get_body_data()
        },
        response = {
            status = ngx.status,
            headers = ngx.resp.get_headers(),
            size = ngx.var.bytes_sent,
        },
        upstream = ngx.var.upstream_addr,
        service_name = route.service_name,
        client_ip = client_ip,
        start_time = ngx.req.start_time() * 1000,
        latency = (ngx.now() - ngx.req.start_time()) * 1000
    }
--    if conf.include_req_body then
--        local body = ngx.req.get_body_data()
--        if body then
--            log.request.body = body
--        end
--    end

--    log = json.encode(log)
--    ngx.log(ngx.ERR, 'log log--->>>>>>>>>>>>>', log)
    --    ngx.log(ngx.ERR, 'log data--->>>>>>>>>>>>>', log)
end

return _M
