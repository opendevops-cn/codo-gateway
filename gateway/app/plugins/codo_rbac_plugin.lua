local jwt = require "app.my_core.resty.jwt"
local resp = require("app.core.response")
local json = require("app.core.json")
--local string = string
local user_info = ngx.shared.user_info
local pairs = pairs
local ck = require("resty.cookie")
local ngx = ngx
local get_headers = ngx.req.get_headers
local rbac_store = require("app.store.rbac_store")
local rbac_verify = require("app.my_core.codo_rbac")

local config = require("app.config")
local codo_rbac_dict = config.get_codo_rbac()
local rbac_secret = codo_rbac_dict.token_secret
local rbac_key = codo_rbac_dict.key

local _M = {
    name = "CRBAC",
    priority = 200,
    desc = "codo风格的RBAC",
    optional = true,
    version = "v1.0"
}

local function decode_auth_token_verify(auth_token)
    local load_token = jwt:verify(rbac_secret, auth_token)
    return load_token
end


function _M.do_in_init_worker()
    rbac_store.init()
end



function _M.do_in_access()
    local cookie, err = ck:new()

    local method = ngx.req.get_method()
    -- 绕过WS
    if method == "GET" and get_headers()["upgrade"] == "websocket" then
        return
    end

    local auth_key = cookie:get(rbac_key)
    --    ngx.log(ngx.ERR, 'cookie auth_key--->>>>>>>>>>>>>', auth_key)

    if auth_key == nil then
        auth_key = get_headers()[rbac_key]
        --        ngx.log(ngx.ERR, 'get_headers auth_key--->>>>>>>>>>>>>', auth_key)
    end

    if auth_key == nil then
        local arg = ngx.req.get_uri_args()
        if arg ~= nil then
            for k, v in pairs(arg) do
                if k == rbac_key then
                    auth_key = v
                end
            end
        else
            return resp.exit(ngx.HTTP_UNAUTHORIZED)
        end
    end

    if auth_key == nil then
        return resp.exit(ngx.HTTP_UNAUTHORIZED)
    end

    -- 解密auth_key
    local load_token = decode_auth_token_verify(auth_key)

    -- 鉴定token是否正常
    if load_token.verified == false then
        return resp.exit(ngx.HTTP_UNAUTHORIZED)
    end

    --    ngx.log(ngx.ERR, 'verified auth_key--->>>>>>>>>>>>> success')
    -- 获得用户id
    local user_id = load_token.payload.data.user_id
    local is_superuser = load_token.payload.data.is_superuser
    user_info['user_id'] = user_id
    user_info['is_superuser'] = is_superuser
    user_info['username'] = load_token.payload.data.username
    user_info['nickname'] = load_token.payload.data.nickname

    --    local uri = ngx.var.uri
    local app_code = ngx.var.target_service_name

    --    ngx.log(ngx.ERR, 'uri,method--->>>>>>>>>>>>>', uri, method, ngx.var.target_service_name )

    if is_superuser == true then
        return
    end

    local uri = ngx.var.origin_uri
    local state = rbac_verify.match(app_code, uri, user_id, method)
    if state == true then
        return
    end

    return resp.exit(ngx.HTTP_FORBIDDEN)
end

return _M
