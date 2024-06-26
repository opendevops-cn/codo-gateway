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
local log = require("app.core.log")
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local _M = {}

function _M.call(modules, method_name, ...)
    for name, m in pairs(modules) do
        local func = m[method_name]
        if not func then
            log.debug("can not found module method, ", name, ".", method_name)
            goto CONTINUE
        end

        local ok, err = pcall(func, ...)
        if not ok then
            log.error("call error:", method_name, " - ", err)
        end

        ::CONTINUE::
    end
end

-- call_alphabeta 顺序调用模块方法
function _M.call_alphabeta(modules, method_name, ...)
    for _, m in ipairs(modules) do
        local func = m[method_name]
        local plugin_name = m.name
        if not func then
            log.debug("can not found module method, ", plugin_name, ".", method_name)
            goto CONTINUE
        end
        log.debug("call, ", plugin_name, ".", method_name)

        local ok, err = pcall(func, ...)
        if not ok then
            log.error("call error:", method_name, " - ", err)
        end

        ::CONTINUE::
    end
end

return _M
