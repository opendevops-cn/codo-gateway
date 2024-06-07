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
local core = require("app.core")
local log = require("app.core.log")
local json = require("app.core.json")
local route_store = require("app.store.route_store")
local discovery_store = require("app.store.discovery_store")
local resp = require("app.core.response")
local ngx_balancer = require("ngx.balancer")
local balancer = require("app.core.balancer")

local _M = {
    name = "discovery",
    desc = "服务发现插件",
    priority = 100,
    optional = true,
    version = "v1.0"
}

function _M.do_in_init_worker()
    discovery_store.init()
    route_store.init()
end

function _M.do_in_rewrite(route)
    local ngx_ctx = ngx.ctx
    local var = ngx.var
    local service_name = route.service_name
    var.target_service_name = service_name

    local svc_node = balancer.find(service_name)
    local upstream = svc_node.upstream

    if not upstream then
        log.error("can not find any service node")
        return resp.exit(ngx.HTTP_NOT_FOUND)
    end


    local dst_domain = svc_node.dst_domain
    local dst_is_https = svc_node.dst_is_https

    if dst_domain ~= "" then
        ngx.var.biz_domain = dst_domain
        log.info(route.prefix, "set Host header: ", dst_domain)
        core.request.set_header(ngx_ctx, "Host", dst_domain)
    end

    if dst_is_https == "yes" then
        log.info(route.prefix, "set https proxy")
        ngx.var.biz_schema = "https"
    end

    log.info("upstream==", upstream, " svc_node==", json.delay_encode(svc_node))

    ngx_ctx.upstream_server = upstream
    ngx_ctx.upstream_node = svc_node
end

function _M.do_in_balancer(route)
    local ngx_ctx = ngx.ctx
    local server = ngx_ctx.upstream_server
    log.info("upstream server: ", server)
    ngx_balancer.set_current_peer(ngx_ctx.upstream_server)
end

return _M
