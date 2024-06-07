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
local error = error
local ipairs = ipairs
local etcd = require("app.core.etcd")
local log = require("app.core.log")
local tab_nkeys = require("table.nkeys")
local core_table = require("app.core.table")
local sso_users = require("app.my_core.sso_users")
local timer = require("app.core.timer")
local json = require("app.core.json")

local _M = {}

local sso_users_timer
local sso_users_watch_timer
-- 防止网络异常导致路由数据监听处理失败，未及时更新路由信息，定时轮训路由配置
local sso_users_refresh_timer

local etcd_prefix = "uc/userinfo/"

local etcd_watch_opts = {
    timeout = 60,
    prev_kv = true
}

-- 查询所有用户信息，返回 list
local function query_list()
    local resp, err = etcd.readdir(etcd_prefix)
    if err ~= nil then
        log.error("failed to load sso_users_list", err)
        return nil, err
    end

    local sso_users_list = {}
    if resp.body.kvs and tab_nkeys(resp.body.kvs) > 0 then
        for _, kv in ipairs(resp.body.kvs) do
            core_table.insert(sso_users_list, kv.value)
        end
    end
    return sso_users_list, nil
end

_M.query_list = query_list

local function refresh_sso_users()
    local sso_users_list, err = query_list()
    if not sso_users_list and tab_nkeys(sso_users_list) < 1 then
        return nil, err
    end
    sso_users.refresh(sso_users_list)
end

local function watch_sso_users_list(ctx)
    log.debug("watch sso_users_list start_revision: ", ctx.start_revision)
    local opts = {
        timeout = etcd_watch_opts.timeout,
        prev_kv = etcd_watch_opts.prev_kv,
        start_revision = ctx.start_revision
    }
    local chunk_fun, err = etcd.watchdir(etcd_prefix, opts)

    if not chunk_fun then
        log.error("sso_users_list chunk err: ", err)
        return
    end
    while true do
        local chunk
        chunk, err = chunk_fun()
        if not chunk then
            if err ~= "timeout" then
                log.error("sso_users_list chunk err: ", err)
            end
            break
        end
        log.debug("sso_users_list watch result: ", json.delay_encode(chunk.result))
        ctx.start_revision = chunk.result.header.revision + 1
        if chunk.result.events then
            for _, event in ipairs(chunk.result.events) do
                log.error("sso_users_list event: ", event.type, " - ", json.delay_encode(event.kv))
                refresh_sso_users()
            end
        end
    end
end

local function _init()
    refresh_sso_users()
    sso_users_watch_timer:recursion()
    sso_users_refresh_timer:every()
end

-- 初始化
function _M.init()
    sso_users_timer = timer.new("sso_users.timer", _init, {delay = 0})
    sso_users_refresh_timer = timer.new("sso_users.refresh.timer", refresh_sso_users, { delay = 3})
    sso_users_watch_timer = timer.new("sso_users.watch.timer", watch_sso_users_list, {delay = 0})
    local ok, err = sso_users_timer:once()
    if not ok then
        error("failed to load sso_users_list: " .. err)
    end
end

return _M
