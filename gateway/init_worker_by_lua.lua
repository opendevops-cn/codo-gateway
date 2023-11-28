local app = require("app")
local admin = require("admin")

app.http_init_worker()
admin.init_worker()