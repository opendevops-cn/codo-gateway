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
local ngx = ngx
local cjson = require("cjson")
local resp = require("app.core.response")
local log = require("app.core.log")
local str_utils = require("app.utils.str_utils")
local time = require("app.core.time")
local discovery_store = require("app.store.discovery_store")

local function list()
    local services, err = discovery_store.query_service_node_list()
    if err then
        log.error("find service nodes error: ", err)
        resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "查询服务节点异常")
        return
    end
    resp.exit(ngx.HTTP_OK, services)
end

local function remove()
    local data = cjson.decode(ngx.req.get_body_data())
    local _, err = discovery_store.delete_etcd_node(data.key)
    if err then
        log.error("delete service node error: ", err)
        resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "删除服务节点异常")
        return
    end
    resp.exit(ngx.HTTP_OK, "ok")
end

local function save()
    local service = cjson.decode(ngx.req.get_body_data())
    service.time = time.now() * 1000
    if str_utils.is_blank(service.key) and discovery_store.is_exsit(service) then
        resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "服务节点已存在")
        return
    end
    local _, err = discovery_store.set_service_node(service)
    if err then
        log.error("save service node error: ", err)
        resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, err)
        return
    end
    resp.exit(ngx.HTTP_OK, "ok")
end

local _M = {
    apis = {
        {
            paths = {[[/api/admin/services/list]]},
            methods = {"GET", "POST"},
            handler = list
        },
        {
            paths = {[[/api/admin/services/remove]]},
            methods = {"DELETE", "POST"},
            handler = remove
        },
        {
            paths = {[[/api/admin/services/save]]},
            methods = {"POST"},
            handler = save
        }
    }
}

return _M
