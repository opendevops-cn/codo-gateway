local limit_req = require "resty.limit.req"
local resp = require("app.core.response")
local ngx = ngx

local plugin_name = "limit-req"

local _M = {
    name = plugin_name,
    priority = 500,
    desc = "漏桶限流",
    optional = true,
    version = "v1.0"
}

-- limit_req_rate 限制 ip 每分钟只能调用 n*60 次 接口（平滑处理请求，即每秒放过5个请求）
-- limit_req_burst 请求速率超过 （limit_req_rate + limit_req_burst）的请求会被直接拒绝

function _M.do_in_access(route)
    local limit_req_rate = route.props.limit_req_rate -- 指定的请求速率（以秒为单位），请求速率超过 rate 但没有超过 （rate + brust）的请求会被加上延时。
    local limit_req_burst = route.props.limit_req_burst -- 请求速率超过 （rate + brust）的请求会被直接拒绝。
    --    local limit_req_internal = route.props.limit_req_internal
--    ngx.log(ngx.ERR, "limit_req_rate: ", limit_req_rate)
    if not limit_req_rate or not limit_req_burst then
        return
    end

    local lim, err = limit_req.new("my_limit_conn_store", limit_req_rate, limit_req_burst)
    if not lim then --没定义共享字典
        ngx.log(ngx.ERR, "failed to instantiate a resty.limit.conn object: ", err)
        return resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- 对于内部重定向或子请求，不进行限制。因为这些并不是真正对外的请求，除非你指定了也要限流。
    --    if limit_req_internal == "no" and ngx.req.is_internal() then
    --        return
    --    end

    local key = ngx.var.binary_remote_addr
    local delay, err = lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return resp.exit(ngx.HTTP_SERVICE_UNAVAILABLE) -- 503
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return resp.exit(ngx.HTTP_INTERNAL_SERVER_ERROR) -- 500  HTTP_SERVICE_UNAVAILABLE
    end
    -- 此方法返回，当前请求需要delay秒后才会被处理，和他前面对请求数
    -- 所以此处对桶中请求进行延时处理，让其排队等待，就是应用了漏桶算法
    if delay >= 0.001 then
        ngx.sleep(delay)
    end
end

return _M


-- | 名称          | 类型    | 必选项 | 默认值 | 有效值                                                                   | 描述                                                                                                                                              |
-- | ------------- | ------- | ------ | ------ | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
-- | limit_req_rate | integer | 必须   |        | limit_req_rate > 0      | 指定的请求速率（以秒为单位），请求速率超过 `rate` 但没有超过 （`rate` + `brust`）的请求会被加上延时。                                             |
-- | limit_req_burst| integer | 必须   |        | limit_req_burst >= 0    | t请求速率超过 （`rate` + `brust`）的请求会被直接拒绝。
