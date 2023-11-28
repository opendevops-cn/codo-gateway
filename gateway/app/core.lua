--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--


-- local utils = require("app.core.utils")
-- sleep    = utils.sleep,
-- utils    = utils,
-- schema   = require("app.schema_def"),
-- string   = require("app.core.string"),
-- http     = require("app.core.http"),
-- tablepool= require("tablepool"),


-- 注册
return {
    version  = require("app.core.version"),
    log      = require("app.core.log"),

    json     = require("app.core.json"),
    table    = require("app.core.table"),
    request  = require("app.core.request"),
    response = require("app.core.response"),
    lrucache = require("app.core.lrucache"),
    lrucache2 = require("app.core.lrucache2"),

    ctx      = require("app.core.ctx"),
    timer    = require("app.core.timer"),

    etcd     = require("app.core.etcd"),
    string   = require("app.core.string"),
    empty_tab= {},
}
