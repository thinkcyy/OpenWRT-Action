module("luci.controller.thinkcy_access", package.seeall)

function index()
        entry({"admin", "network", "thinkcy-access"}, template("thinkcy_access/main"), _("Temporary WAN Access"), 89)
        entry({"admin", "network", "thinkcy-access", "action"}, call("action")).leaf = true
end

function action()
        local http = require "luci.http"
        local sys = require "luci.sys"
        local op = http.formvalue("op") or ""
        local mac = http.formvalue("mac") or ""
        local minutes = http.formvalue("minutes") or ""
        local name = http.formvalue("name") or ""
        local function quote(s)
                return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
        end
        local cmd
        if op == "grant" then
                cmd = "/usr/libexec/thinkcy-access grant " .. quote(mac) .. " " .. quote(minutes)
        elseif op == "add" then
                cmd = "/usr/libexec/thinkcy-access add " .. quote(mac) .. " " .. quote(name)
        elseif op == "delete" then
                cmd = "/usr/libexec/thinkcy-access delete " .. quote(mac)
        else
                http.status(400, "Bad Request")
                http.write("Unknown operation")
                return
        end
        local rc = sys.call(cmd .. " >/tmp/thinkcy-access.out 2>&1")
        http.prepare_content("application/json")
        http.write_json({ ok = (rc == 0), output = (sys.exec("cat /tmp/thinkcy-access.out") or "") })
end
