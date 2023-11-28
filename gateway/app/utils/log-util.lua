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
local core = require("app.core")
local ngx  = ngx
local pairs = pairs
local str_utils = require("app.utils.str_utils")

local _M = {}

local function get_log(ngx, route)
    local client_ip = str_utils.split(ngx.var.proxy_add_x_forwarded_for, ',')[1]
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
    return log
end

_M.get_log = get_log

local function get_full_log(ngx, conf)
    local ctx = ngx.ctx.api_ctx
    local var = ctx.var
    local service_id
    local route_id
    local url = var.scheme .. "://" .. var.host .. ":" .. var.server_port
                .. var.request_uri
    local matched_route = ctx.matched_route and ctx.matched_route.value

    if matched_route then
        service_id = matched_route.service_id or ""
        route_id = matched_route.id
    else
        service_id = var.host
    end

    local client_ip = str_utils.split(ngx.var.proxy_add_x_forwarded_for, ',')[1]
    local log =  {
        request = {
            url = url,
            uri = var.request_uri,
            method = ngx.req.get_method(),
            headers = ngx.req.get_headers(),
            querystring = ngx.req.get_uri_args(),
            size = var.request_length
        },
        response = {
            status = ngx.status,
            headers = ngx.resp.get_headers(),
            size = var.bytes_sent
        },
        upstream = var.upstream_addr,
        service_id = service_id,
        route_id = route_id,
        consumer = ctx.consumer,
        client_ip = client_ip,
        start_time = ngx.req.start_time() * 1000,
        latency = (ngx.now() - ngx.req.start_time()) * 1000
    }

    if conf.include_req_body then
        local body = ngx.req.get_body_data()
        if body then
            log.request.body = body
        else
            local body_file = ngx.req.get_body_file()
            if body_file then
                log.request.body_file = body_file
            end
        end
    end

    return log
end

_M.get_full_log = get_full_log


function _M.get_req_original(ctx, conf)
    local headers = {
        ctx.var.request, "\r\n"
    }
    for k, v in pairs(ngx.req.get_headers()) do
        core.table.insert_tail(headers, k, ": ", v, "\r\n")
    end
    -- core.log.error("headers: ", core.table.concat(headers, ""))
    core.table.insert(headers, "\r\n")

    if conf.include_req_body then
        core.table.insert(headers, ctx.var.request_body)
    end

    return core.table.concat(headers, "")
end


return _M
