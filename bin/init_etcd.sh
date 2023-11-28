#!/bin/bash

value='{"status":1,"key":"\/api\/p\/*","props":{"rewrite_url_regex":"^\/api\/p\/","rewrite_replace":"\/"},"service_name":"mg","time":1694490078055,"protocol":"http","_rowKey":13,"remark":"PAAS平台","plugins":["discovery","rewrite","redis-logger","CRBAC"],"prefix":"\/api\/p\/*","propsData":{"rewrite_url_regex":"^\/api\/p\/","rewrite_replace":"\/"}}'
etcdctl put '/my2/gw/routes/api/p/*' "$value"
