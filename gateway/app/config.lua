--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local json = require("app.core.json")
local str_utils = require("app.utils.str_utils")
local ngx_config = ngx.config
local error = error

local _M = {}

local app_config = {
    appName = "codo-gateway",
    env = "test",
    etcd = {
        http_host = "http://127.0.0.1:2379",
        data_prefix = "/my/gw/",
    },
    jwt_auth = {
        key = "auth_key",
        token = "xxxxxx",
    },
    codo_rbac = {
        key = "auth",
        token_secret = "xxxxxx",
    },
    sso2internal = {
        sso_token_secret = "xxxxxx",
        sso_jwt_key = "sso_token",
        internal_token_secret = "xxxxxx",
        internal_jwt_key = "auth_key",
    },
    mfa = {
        mfa_secret = "xxxxxx",
        mfa_key = "mfa_key"
    },
    plugins_config = {
        ["redis-logger"] = {
            host = "127.0.0.1",
            port = 6379,
            auth_pwd = "1234567",
            db = 1,
            alive_time = 604800,
            channel = "gw",
            full_log = "no"
        }
    },
    admin = {
        jwt_secret = "xxxx",
        account = {
            admin = {
                password = "tainiubile",
                info = {
                    roles = { "admin" },
                    introduction = "I am a super administrator",
                    avatar = "https://xxx.com/1.gif",
                    name = "管理员"
                }
            }
        }
    },
    tokens = {
        ["xxx"] = {
            desc = "系统默认 api token"
        }
    }
}

-- 用于递归地检查配置表并使用环境变量更新
local function update_config_with_env(config, parent_key)
    for k, v in pairs(config) do
        local env_key = parent_key and (parent_key .. "." .. k) or k
        if type(v) == "table" then
            -- 递归处理嵌套表
            config[k] = update_config_with_env(v, env_key)
        else
            -- 尝试从环境变量中获取新的配置值
            local env_value = os.getenv(env_key)
            print("env_key======", env_key)
            if env_value then
                config[k] = env_value
            end
        end
    end
    return config
end

function _M.init(config_file)
    if not str_utils.start_with(config_file, "/") then
        config_file = ngx_config.prefix() .. config_file
    end
    local json_conf = json.decode_json_file(config_file)
    if not json_conf then
        error("load config file failed")
        return
    end
    app_config = json_conf
    -- 使用环境变量更新配置
    app_config = update_config_with_env(app_config, "CODO_GATEWAY")

    print("load config success", json.delay_encode(app_config, false))
end

local function get(key)
    if not app_config then
        error("etcd config not init")
        return nil
    end
    return app_config[key]
end

_M.get = get

-- 获取etcd配置
function _M.get_etcd_config()
    return get("etcd")
end

function _M.get_jwt_auth()
    return get("jwt_auth")
end

function _M.get_sso2internal()
    return get("sso2internal")
end

function _M.get_mfa()
    return get("mfa")
end

function _M.get_codo_rbac()
    return get("codo_rbac")
end

function _M.get_plugins_config(plugin_name)
    local _plugins_config = get("plugins_config")
    if _plugins_config then
        return _plugins_config[plugin_name]
    end
    error("plugins_config not found!")
    return nil
end

-- 是否是测试环境
function _M.is_test()
    return not app_config.env == "prod"
end

return _M
