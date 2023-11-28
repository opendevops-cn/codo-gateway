###
 # @Author: cA7dEm0n
 # @Blog: http://www.a-cat.cn
 # @Since: 2020-12-30 17:14:05
 # @Motto: 欲目千里，更上一层
 # @message: 本地DEBUG测试
### 

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
POD_NAME="gateway"
IMAGE_NAME="code/gateway"

run() {
    docker ps |grep -q ${POD_NAME} && exit 0
    docker run -d -p 8888:8888 \
        -v ${SCRIPT_DIR}/conf:/usr/local/openresty/nginx/conf \
        -v ${SCRIPT_DIR}/deps:/usr/local/openresty/nginx/deps/ \
        -v ${SCRIPT_DIR}/gateway:/usr/local/openresty/nginx/gateway/ \
        -v ${SCRIPT_DIR}/init:/usr/local/openresty/nginx/init/ \
        -v ${SCRIPT_DIR}/rockspec:/usr/local/openresty/nginx/rockspec/ \
        --name ${POD_NAME} ${IMAGE_NAME}
}

log() {
    docker logs -f ${POD_NAME}
}

stop() {
    docker stop ${POD_NAME}
}

start() {
    docker start ${POD_NAME}
}

rm_() {
    docker rm ${POD_NAME}
}

reload() {
    docker exec ${POD_NAME} /usr/local/openresty/bin/openresty -s reload
}

init_services() {
    local token=$1
    curl http://127.0.0.1:8888/api/mg/admin/services/save -H "X-Api-Token: ${token}" -X POST -d'
    {
        "service_name": "demo1",
        "upstream": "127.0.0.1:1024",
        "weight": 1,
        "status": 1
    }'
}

init_routes() {
    local token=$1
    curl http://127.0.0.1:8888/api/mg/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "prefix": "/openapi/demo1/*",
    "status": 1,
    "service_name": "demo1",
    "protocol": "http",
    "plugins": ["discovery", "tracing", "rewrite", "redis-logger"],
    "props": {
        "rewrite_url_regex": "^/openapi/(.*)/",
        "rewrite_replace": "/openapi/"
    }
}'
}


init() {
    token=e09d6153f1c15395397be3639d144794
    # curl http://127.0.0.1:8888/api/mg/admin/plugins/list -H "X-Api-Token: e09d6153f1c15395397be3639d144794"
    init_services ${token}
    init_routes ${token}
}

restart() {
    stop
    start
}

$*
