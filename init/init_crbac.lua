local app = require("app.init")
-- init
do
    app.http_init()
end -- end do

local os = os
local ngx = ngx
local ipairs = ipairs
local json = require("app.core.json")
local rbac_store = require("app.store.rbac_store")
ngx.say("load data: -----------------------------------------------------------------")
local data_file = os.getenv("BASE_DIR") .. "/init/init_crbac.json"
ngx.say("load data: " .. data_file)
local datas = json.decode_json_file(data_file)

for _, data in ipairs(datas) do
    rbac_store.save_rbac(data)
end

ngx.say("init rbac data")
