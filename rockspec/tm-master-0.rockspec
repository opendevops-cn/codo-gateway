package = "tm"
version = "master-0"
supported_platforms = {"linux", "macosx"}

source = {
    url = "git://github.com/apache/apisix",
    branch = "master",
}

description = {
    summary = "基于 apisix 实现的轻量级网关服务，有问题去看apisix文档和代码就完事了",
    homepage = "https://github.com/ss1917/api-gateway/",
    license = "GPL v3.0",
}

dependencies = {
    "lua-resty-template = 1.9",
    "lua-resty-etcd = 1.4.3",
    "lua-resty-balancer = 0.02rc5",
    "lua-resty-ngxvar = 0.5.2",
    "lua-resty-jit-uuid = 0.0.7",
    "lua-resty-healthcheck-api7 = 2.2.0",
    "lua-resty-jwt = 0.2.0",
    "lua-resty-hmac-ffi = 0.05",
    "lua-resty-cookie = 0.1.0",
    "lua-resty-session = 2.24",
    "opentracing-openresty = 0.1",
    "lua-resty-radixtree = 2.5",
    "lua-protobuf = 0.3.1",
    "lua-resty-openidc = 1.7.2-1",
    "luafilesystem = 1.7.0-2",
    "lua-tinyyaml = 1.0",
    "lua-resty-prometheus = 1.1",
    "jsonschema = 0.9.3",
    "lua-resty-ipmatcher = 0.6",
    "lua-resty-kafka = 0.07",
    "lua-resty-logger-socket = 2.0-0",
    "skywalking-nginx-lua = 0.3-0",
    "base64 = 1.5-2",
    "dkjson = 2.5-2",
    "resty-redis-cluster = 1.02-4",
    "lua-resty-expr = 1.0.0",
    "graphql = 0.0.2",
}

build = {
    type = "make",
    build_variables = {
        CFLAGS="$(CFLAGS)",
        LIBFLAG="$(LIBFLAG)",
        LUA_LIBDIR="$(LUA_LIBDIR)",
        LUA_BINDIR="$(LUA_BINDIR)",
        LUA_INCDIR="$(LUA_INCDIR)",
        LUA="$(LUA)",
    },
    install_variables = {
        INST_PREFIX="$(PREFIX)",
        INST_BINDIR="$(BINDIR)",
        INST_LIBDIR="$(LIBDIR)",
        INST_LUADIR="$(LUADIR)",
        INST_CONFDIR="$(CONFDIR)",
    },
}
