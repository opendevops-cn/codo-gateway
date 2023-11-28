local log = require("app.core.log")
local ngx = ngx

local _M = {
    name = "rewrite",
    priority = 6000,
    desc = "url重写插件",
    optional = true,
    version = "v1.0"
}

function _M.do_in_rewrite(route)
    local req = ngx.req
    local re = ngx.re
    local var = ngx.var

    local rewrite_url_regex = route.props.rewrite_url_regex
    if not rewrite_url_regex then
        log.info("rewrite props[rewrite_url_regex] not set")
        return
    end

    local rewrite_replace = route.props.rewrite_replace
    if not rewrite_url_regex then
        log.info("rewrite props[rewrite_replace] not set")
        return
    end

    local uri = var.uri

    local target_uri, _, err = re.gsub(uri, rewrite_url_regex, rewrite_replace, "jo")
    if err then
        log.error("rewrite url error: ", err)
        return
    end

    log.info("rewrite url ==> origin_uri: ", var.origin_uri, ", target_uri: ", target_uri)
    req.set_uri(target_uri, false)
end

return _M
