--local routes = require "gateway.admin.routes"
--
-- @Author: cA7dEm0n
-- @Blog: http://www.a-cat.cn
-- @Since: 2020-12-31 15:02:28
-- @Motto: 欲目千里，更上一层
-- @message: redis日志
--
local ngx = ngx

local redis = require "resty.redis"
redis.add_commands("xadd")

local core  = require("app.core")
local user_info = ngx.shared.user_info
local batch_processor = require("app.utils.batch-processor")
local log_util        = require("app.utils.log-util")

-- plugin config
local plugin_name = "redis-logger"
local config = require("app.config")
local get_plugins_config = config.get_plugins_config

-- buffers
local stale_timer_running = false
local timer_at = ngx.timer.at
local buffers = {}



local _M = {
    name = plugin_name,
    desc = "Redis日志",
    optional = true,
    version = "v0.1"
}


local function connect(conf)

    local red = redis:new()

    red:set_timeout(1000)

    local ok, err = red:connect(conf['host'], conf['port'])

    if not ok then
        return false
    end

    red:auth(conf['auth_pwd'])

    ok, err = red:select(conf['db'])
    if not ok then
        return false
    end
    return red
end

local function publish_log(conf, key, value)
    local red = connect(conf)
    if red == false then
        return false
    end
    local ok, err = red:xadd(conf["channel"], "*", key, value)
    if not ok then
        core.log.error(err)
        return false
    end
    return true
end

-- remove stale objects from the memory after timer expires
local function remove_stale_objects(premature)
    if premature then
        return
    end

    for key, batch in ipairs(buffers) do
        if #batch.entry_buffer.entries == 0 and #batch.batch_to_process == 0 then
            core.log.warn("removing batch processor stale object, conf: ",
                          core.json.delay_encode(key))
            buffers[key] = nil
        end
    end

    stale_timer_running = false
end


-- config
local buffers_config = {
    name = plugin_name,
    retry_delay = 1,
    batch_max_size = 1000,
    max_retry_count = 1,
    buffer_duration = 60,
    inactive_timeout = 3
}

local function default_plugin_conf(conf)
    local _conf =  {
        host = conf.host or '127.0.0.1',
        port = conf.port or 6379,
        auth_pwd = conf.auth_pwd or '123456',
        db = conf.db or 8,
        alive_time = conf.alive_time or 3600 * 24 * 7,
        channel = conf.channel or 'gw',
        full_log = conf.full_log or 'no'
    }
    return _conf
end

-- get config
local redis_config

local read_config = get_plugins_config(plugin_name)
redis_config = default_plugin_conf(read_config)

function _M.do_in_log(route)
    -- local entry = log_util.get_full_log(ngx, {include_req_body=true})
    if  redis_config.full_log  == 'no' and  ngx.req.get_method() == "GET" then
        return
    end

    local entry = log_util.get_log(ngx, route)

    entry['user_info'] = {
        user_id = user_info.user_id,
        username = user_info.username,
        nickname = user_info.nickname,
    }

    if not stale_timer_running then
        -- run the timer every 30 mins if any log is present
        timer_at(1800, remove_stale_objects)
        stale_timer_running = true
    end

    local log_buffer = buffers[plugin_name]
    if log_buffer then
        log_buffer:push(entry)
        return
    end


    -- push function
    local func = function(entries, batch_max_size)

        -- redis connect
        local red = connect(redis_config)
        if red == false then
            return false
        end

        local _nowtime
        _nowtime = os.date('%Y%m%d%H', os.time())

        if batch_max_size == 1 then
            local data, err = core.json.encode(entries[1])
            if not data then
                return false, 'error occurred while encoding the data: ' .. err
            end

            -- red:xadd
            for i,k in ipairs(entries[1]) do
                core.log.error(i, k)
            end
            local ok, _err = red:xadd(
                redis_config["channel"],
                "*",
                _nowtime,
                data
            )
            if not ok then
                core.log.error(_err)
                return false
            end
        else
            -- entries list
            for _, v in pairs(entries) do
                local data, err = core.json.encode(v)
                if not data then
                    core.log.error('error occurred while encoding the data: ' .. err)
                end

                local ok, _err = red:xadd(
                    redis_config["channel"],
                    "*",
                    _nowtime,
                    data
                )
                if not ok then
                    core.log.error(_err)
                end -- if not ok
            end  -- for _, v in pairs(data)
        end -- else
        return true
    end

    local err
    log_buffer, err = batch_processor:new(func, buffers_config)

    if not log_buffer then
        core.log.error("error when creating the batch processor: ", err)
        return
    end

    buffers[plugin_name] = log_buffer
    log_buffer:push(entry)
end

return _M
