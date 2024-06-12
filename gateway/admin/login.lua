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
local cjson = require("cjson")
local jwt = require "resty.jwt"
local ngx = ngx
local now = ngx.now
local update_time = ngx.update_time
local config_get = require("app.config").get
local resp = require("app.core.response")

local function login()
    resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "请从 codo 统一认证登陆")
end

local function info()
    resp.exit(ngx.OK, ngx.ctx.admin_login_user)
end

local function logout()
    resp.exit(ngx.OK, "ok")
end

local _M = {
    apis = {
        {
            paths = {[[/admin/login]]},
            methods = {"POST"},
            handler = login,
            check_login = false
        },
        {
            paths = {[[/admin/user/info]]},
            methods = {"POST", "GET"},
            handler = info
        },
        {
            paths = {[[/admin/logout]]},
            methods = {"POST", "GET"},
            handler = logout
        }
    }
}

return _M
