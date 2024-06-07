local jwt = require "app.my_core.resty.jwt"
local sso_users = require "app.my_core.sso_users"
local sso_users_store = require "app.store.sso_users_store"
local user_info = ngx.shared.user_info
local resp = require("app.core.response")
local ck = require("resty.cookie")
local core = require("app.core")
local log = require("app.core.log")
local json = require("app.core.json")
local string = string
local ngx = ngx
local get_headers = ngx.req.get_headers
local pairs = pairs
local config = require("app.config")
local mfa_config = config.get_mfa()

local _M = {
    name = "mfa",
    priority = 400,
    desc = "MFA认证中间件",
    optional = true,
    version = "v1.0"
}

local mfa_secret = mfa_config.mfa_secret
local mfa_key = mfa_config.mfa_key

local function encode_jwt_token(token_secret, payload)
    return jwt:sign(
        token_secret,
        {
            header = { typ = "JWT", alg = "HS256" },
            payload = payload
        }
    )
end

local function decode_jwt_token(token_secret, jwt_token)
    local load_token = jwt:verify(token_secret, jwt_token)
    return load_token
end

function _M.do_in_init_worker()
    sso_users_store.init()
end

function _M.do_in_access()
    local ngx_ctx = ngx.ctx
    local cookie = ck:new()

    -- 绕过GET
    if ngx.req.get_method() == "GET" then
        return
    end


    -- 绕过 PATCH
    if ngx.req.get_method() == "PATCH" then
        return
    end

    -- 超管跳过认证
    if user_info.is_superuser then
        return
    end


    -- 获取内部的 jwt
    local auth_key = cookie:get(mfa_key)

    if auth_key == nil then
        auth_key = get_headers()[mfa_key]
    end

    if auth_key == nil then
        local arg = ngx.req.get_uri_args()
        if arg ~= nil then
            for k, v in pairs(arg) do
                if k == mfa_key then
                    auth_key = v
                end
            end
        end
    end

    if auth_key == nil then
        return resp.exit(423, "MFA认证失败")
    end

    local load_token = decode_jwt_token(mfa_secret, auth_key)

    -- 鉴定token是否正常
    if load_token.verified == false then
        return resp.exit(423, "MFA认证失败")
    end

    core.request.set_header(ngx_ctx, mfa_key, auth_key)
    return
end

return _M
