#! /bin/bash -x

sleep 1

token=e09d6153f1c15395397be3639d144794
mg_addr='127.0.0.1:8010'
## 管理后台


echo
curl http://127.0.0.1:8888/api/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/api/mg/*",
    "protocol": "http",
    "remark": "",
    "prefix": "/api/mg/*",
    "service_name": "mg",
    "status": 1,
    "plugins": [
        "discovery",
        "tracing",
        "rewrite"
    ],
    "props": {
        "rewrite_url_regex": "^/api/mg/",
        "rewrite_replace": "/"
    }
}'
### 鉴权
curl http://127.0.0.1:8888/api/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/api/accounts/authorization/",
    "protocol": "http",
    "remark": "鉴权",
    "prefix": "/api/accounts/authorization/",
    "service_name": "mg",
    "status": 1,
    "plugins": [
        "discovery",
        "tracing",
        "limit-req",
        "rewrite"
    ],
    "props": {
      "limit_req_rate": 5,
      "rewrite_replace": "/",
      "rewrite_url_regex": "^/api/",
      "limit_req_burst": 5
    }
}'

echo

### 登录
curl http://127.0.0.1:8888/api/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/api/accounts/login/",
    "protocol": "http",
    "remark": "登录",
    "prefix": "/api/accounts/login/",
    "service_name": "mg",
    "status": 1,
    "plugins": [
        "discovery",
        "tracing",
        "limit-req",
        "rewrite"
    ],
    "props": {
      "limit_req_rate": 5,
      "rewrite_replace": "/",
      "rewrite_url_regex": "^/api/",
      "limit_req_burst": 5
    }
}'

echo



echo



curl http://127.0.0.1:8888/api/admin/routes/save -H "X-Api-Token: ${token}" -X POST -d '
{
    "key": "/api/mg/*",
    "protocol": "http",
    "remark": "",
    "prefix": "/api/mg/*",
    "service_name": "mg",
    "status": 1,
    "plugins": [
        "discovery",
        "tracing",
        "rewrite",
        "auth-rbac"
    ],
    "props": {
        "rewrite_url_regex": "^/api/mg/",
        "rewrite_replace": "/"
    }
}'

echo


curl http://127.0.0.1:8888/api/admin/services/save -H "X-Api-Token: ${token}" -X POST -d "
{
    \"key\": \"/mg/${mg_addr}\",
    \"service_name\": \"mg\",
    \"upstream\": \"${mg_addr}\",
    \"weight\": 1,
    \"status\": 1
}"
echo
