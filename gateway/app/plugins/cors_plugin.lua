--
-- Created by IntelliJ IDEA.
-- User: shenshuo
-- Date: 2021/8/9
-- Time: 15:22
-- To change this template use File | Settings | File Templates.
--

local ngx = ngx
local type = type
local core = require("app.core")
local plugin_name = "cors"
local ctx = core.ctx
local get_headers = ngx.req.get_headers

local _M = {
    name = plugin_name,
    priority = 200,
    desc = "cors跨域处理",
    optional = true,
    version = "v0.1"
}

local function set_cors_headers(conf, ctx)
    local allow_methods = conf.allow_methods
    if allow_methods == "**" or not allow_methods then
        allow_methods = "GET,POST,PUT,DELETE,PATCH,HEAD,OPTIONS,CONNECT,TRACE"
    end
    ngx.log(ngx.ERR, 'cors_allow_origins--->>>>>>>>>>>>> ', ctx.cors_allow_origins)
    core.response.set_header("Access-Control-Allow-Origin", ctx.cors_allow_origins)
    if ctx.cors_allow_origins ~= "*" then
        core.response.add_header("Vary", "Origin")
    end

    core.response.set_header("Access-Control-Allow-Methods", allow_methods)

    local allow_max_age = 600
    if conf.max_age and type(conf.max_age) == "number" then
        allow_max_age = conf.max_age
    end
    core.response.set_header("Access-Control-Max-Age", allow_max_age)

    local expose_headers = conf.expose_headers or "*"
    core.response.set_header("Access-Control-Expose-Headers", expose_headers)

    local allow_headers = conf.allow_headers or "*"

    if conf.allow_headers == "**" then
        core.response.set_header("Access-Control-Allow-Headers",
            core.request.header(ctx, "Access-Control-Request-Headers"))
    else
        core.response.set_header("Access-Control-Allow-Headers", allow_headers)
    end
    if conf.allow_credential then
        core.response.set_header("Access-Control-Allow-Credentials", true)
    end
end


local function process_with_allow_origins(conf, ctx, req_origin)
    local allow_origins = conf.allow_origins or "*"
    if allow_origins == "**" then
        allow_origins = req_origin or "*"
    end
    ngx.log(ngx.ERR, 'allow_origins--->>>>>>>>>>>>>', allow_origins)
    return allow_origins
end


function _M.do_in_rewrite(route)
    local method = ngx.req.get_method()
    if method == "OPTIONS" then
        return 200
    end
end

-- allow_origins *
-- allow_methods *
-- max_age    600
-- allow_headers  *
-- expose_headers *
-- allow_credential  false

function _M.do_in_header_filter(route)
    local conf = route.props
    local req_origin = core.request.header(ctx, "Origin")
    --    ngx.log(ngx.ERR, 'get_headers Origin-->>>>>>>>>>>>>', get_headers()['Origin'])
    --    ngx.log(ngx.ERR, 'core.request.header  req_origin--->>>>>>>>>>>>>', req_origin)

    local allow_origins
    allow_origins = process_with_allow_origins(conf, ctx, req_origin)

    if allow_origins then
        ctx.cors_allow_origins = allow_origins
        set_cors_headers(conf, ctx)
    end
end


return _M
