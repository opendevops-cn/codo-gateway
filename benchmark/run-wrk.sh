#! /bin/bash -x

sleep 1

token=e09d6153f1c15395397be3639d144794

curl http://127.0.0.1:8888/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/innerapi/hello/*",
    "protocol": "http",
    "remark": "",
    "prefix": "/innerapi/hello/*",
    "service_name": "hello",
    "status": 1,
    "plugins": [
        "discovery",
        "tracing",
        "rewrite"
    ],
    "props": {
        "rewrite_url_regex": "^/innerapi/(.*)/",
        "rewrite_replace": "/"
    }
}'

echo

curl http://127.0.0.1:8888/admin/services/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/hello/127.0.0.1:8080",
    "service_name": "hello",
    "upstream": "127.0.0.1:8080",
    "weight": 1,
    "status": 1
}'

echo

sleep 2
echo 'benchmark start'

mkdir -p out
wrk -d 5 -c 16 --latency http://127.0.0.1:8888/innerapi/hello/api > out/wrk.out

cat out/wrk.out
echo 'benchmark end'
