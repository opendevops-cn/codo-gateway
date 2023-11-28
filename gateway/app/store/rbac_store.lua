--
-- Created by IntelliJ IDEA.
-- User: shenshuo
-- Date: 2020/11/30
-- Time: 16:06
-- CODO 风格的RBAC
--

local error = error
local ipairs = ipairs
local etcd = require("app.core.etcd")
local log = require("app.core.log")
local tab_nkeys = require("table.nkeys")
local str_utils = require("app.utils.str_utils")
local core_table = require("app.core.table")
local time = require("app.core.time")
local codo_rbac = require("app.my_core.codo_rbac")
local timer = require("app.core.timer")
local json = require("app.core.json")
local ngx = ngx
local type = type

local _M = {}

local crbac_timer
local crbac_watch_timer
-- 防止网络异常导致路由数据监听处理失败，未及时更新路由信息，定时轮训路由配置
local crbac_refresh_timer

local etcd_prefix = "codorbac"

local etcd_watch_opts = {
    timeout = 60,
    prev_kv = true
}

-- 构造RBAC前缀
local function get_etcd_key(key)
    return etcd_prefix .. key
end


-- 配置是否存在
local function is_exsit(key)
    local etcd_key = get_etcd_key(key)
    local res, err = etcd.get(etcd_key)
    return not err and res.body.kvs and tab_nkeys(res.body.kvs) > 0
end

_M.is_exsit = is_exsit

-- 查询所有rbac配置，返回 list
local function query_list()
    local resp, err = etcd.readdir(etcd_prefix)
    if err ~= nil then
        log.error("failed to readdir codo rbac", err)
        return nil, err
    end

    local crbac = {}

    --ngx.log(ngx.ERR, 'rbac query list--->',etcd_prefix, json.encode( resp.body.kvs))
    if resp.body.kvs and tab_nkeys(resp.body.kvs) > 0 then
        for _, kv in ipairs(resp.body.kvs) do
            core_table.insert(crbac, kv.value)
        end
    end
    return crbac, nil
end

_M.query_list = query_list

local function query_enable_list()
    local list, err = query_list()
    if not list and tab_nkeys(list) < 1 then
        return nil, err
    end
    --    ngx.log(ngx.ERR, 'query_enable_list ----------------->',type(list),json.encode(list))
    local crbac = {}
    for _, rbac in ipairs(list) do
        if rbac.status == 1 then
            core_table.insert(crbac, rbac)
        end
    end
    return crbac, nil
end

_M.query_enable_list = query_enable_list

local function refresh_crbac()
    local rbac_data, err = query_enable_list()
    if not rbac_data and tab_nkeys(rbac_data) < 1 then
        return nil, err
    end
     codo_rbac.refresh(rbac_data)
end

local function watch_crbac(ctx)
    log.info("watch crbacs start_revision: ", ctx.start_revision)
    local opts = {
        timeout = etcd_watch_opts.timeout,
        prev_kv = etcd_watch_opts.prev_kv,
        start_revision = ctx.start_revision
    }
    local chunk_fun, err = etcd.watchdir(etcd_prefix, opts)

    if not chunk_fun then
        log.error("crbacs chunk err: ", err)
        return
    end
    while true do
        local chunk
        chunk, err = chunk_fun()
        if not chunk then
            if err ~= "timeout" then
                log.error("rabc chunk err: ", err)
            end
            break
        end
        log.info("rabc watch result: ", json.delay_encode(chunk.result))
        ctx.start_revision = chunk.result.header.revision + 1
        if chunk.result.events then
            for _, event in ipairs(chunk.result.events) do
                --log.error("rabc event: ", event.type, " - ", json.delay_encode(event.kv))
                refresh_crbac()
            end
        end
    end
end

-- 删除权限
local function remove_rbac_rule(key)
    local _, err = etcd.delete(get_etcd_key(key))
    if not err then
        refresh_crbac()
    end
    return err
end

_M.remove_rbac_rule = remove_rbac_rule

-- 保存RBAC配置
function _M.save_rbac_rules(data)
    --    data.key = data.prefix
    local key = str_utils.trim(data.key)
    local etcd_key = get_etcd_key(key)
    data.time = time.now() * 1000
    local _, err = etcd.set(etcd_key, data)
    if err then
        log.error("save route error: ", err)
        return err
    end
    refresh_crbac()
    return nil
end

local function _init()
    log.error(" rbac rule_init: ")
    refresh_crbac()
    crbac_watch_timer:recursion()
    crbac_refresh_timer:every()
end

-- 初始化
function _M.init()
    crbac_timer = timer.new("crbac.timer", _init, { delay = 0 })
    crbac_refresh_timer = timer.new("crbac.refresh.timer", refresh_crbac, { delay = 3 })
    crbac_watch_timer = timer.new("crbac.watch.timer", watch_crbac, { delay = 0 })
    local ok, err = crbac_timer:once()
    if not ok then
        error("failed to load crbac: " .. err)
    end
end

return _M
