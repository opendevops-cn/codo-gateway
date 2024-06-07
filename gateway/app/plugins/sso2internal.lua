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
local sso2internal_config = config.get_sso2internal()

local _M = {
    name = "sso2internal",
    priority = 100,
    desc = "将外部的 SSO TOKEN 转换成 内部的 AUTH KEY，用于接入外部系统",
    optional = true,
    version = "v1.0"
}

local sso_token_secret = sso2internal_config.sso_token_secret
local sso_jwt_key = sso2internal_config.sso_jwt_key
local internal_token_secret = sso2internal_config.internal_token_secret
local internal_jwt_key = sso2internal_config.internal_jwt_key

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
    local current_time = ngx.time()

    -- 绕过WS
    if ngx.req.get_method() == "GET" and get_headers()["upgrade"] == "websocket" then
        return
    end

    -- 获取内部的 jwt
    local auth_key = cookie:get(internal_jwt_key)

    if auth_key == nil then
        local arg = ngx.req.get_uri_args()
        if arg ~= nil then
            for k, v in pairs(arg) do
                if k == internal_jwt_key then
                    auth_key = v
                end
            end
        end
    end

    -- 尝试获取 SSO TOKEN
    if auth_key == nil then
        local sso_jwt_token = cookie:get(sso_jwt_key)
        -- 没有 SSO TOKEN 直接返回
        if sso_jwt_token == nil then
            return
        end

        -- 解密 sso jwt token
        local sso_token_data = decode_jwt_token(sso_token_secret, sso_jwt_token)

        --log.info("sso_token_data ,", json.delay_encode(sso_token_data, false), "sso_token_secret ", sso_token_secret)

        local email = sso_token_data.payload.email
        local sso_user = sso_users.get_user(email)
        local jwt_token = encode_jwt_token(internal_token_secret, {
            sub = "my token",
            exp = current_time + 86400,
            iat = current_time,
            nbf = current_time,
            data = {
                user_id = sso_user.codo_user_id,
                username = sso_user.name,
                nickname = sso_user.name,
                email = email,
                is_superuser = sso_user.codo_is_superuser,
            }
        })
        auth_key = jwt_token

        -- set cookie
        cookie:set({
            key = internal_jwt_key,
            value = jwt_token,
            path = "/",
        })
        cookie:set({
            key = "is_login",
            value = "yes",
            path = "/",
        })
    end

    log.debug("auth_key ==== ", auth_key)

    if auth_key then
        -- 设置 header 并且 "_" 切换为 "-"
        core.request.set_header(ngx_ctx, string.gsub(internal_jwt_key,"_","-"), auth_key)
    end
    return
end

return _M
