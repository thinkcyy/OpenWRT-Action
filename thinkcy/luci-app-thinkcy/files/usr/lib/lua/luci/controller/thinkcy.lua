module("luci.controller.thinkcy", package.seeall)

function index()
    -- Check if we have proper permissions
    if not nixio.fs.access("/etc/config/thinkcy") then
        return
    end
    
    -- Add main entry to System menu
    entry({"admin", "system", "thinkcy"}, 
          cbi("thinkcy/thinkcy", {hidesavebtn=false, autoapply=true}), 
          _("ThinkCy Settings"), 60)
    
    -- Add status page
    entry({"admin", "system", "thinkcy", "status"}, 
          call("action_status"), 
          _("Service Status"), 61).leaf = true
    
    -- Add log viewer
    entry({"admin", "system", "thinkcy", "log"}, 
          call("action_log"), 
          _("View Logs"), 62).leaf = true
    
    -- Add system info page
    entry({"admin", "system", "thinkcy", "system"}, 
          call("action_system_info"), 
          _("System Info"), 63).leaf = true
    
    -- Set ACL dependencies
    entry({"admin", "system", "thinkcy", "apply"}, 
          call("action_apply"), 
          nil).leaf = true
end

function action_status()
    local http = require "luci.http"
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    
    -- Load configuration
    uci:load("thinkcy")
    local clash_enabled = uci:get("thinkcy", "config", "clash_enable") or "0"
    local vpn_enabled = uci:get("thinkcy", "config", "vpn_enable") or "0"
    local ddns_enabled = uci:get("thinkcy", "config", "ddns_enable") or "0"
    
    -- Check service status
    local function check_service(name)
        local cmd = string.format("/etc/init.d/%s status 2>/dev/null", name)
        local handle = io.popen(cmd)
        local result = handle:read("*a") or ""
        handle:close()
        return result:match("running") ~= nil
    end
    
    local data = {
        config = {
            clash = clash_enabled == "1",
            vpn = vpn_enabled == "1",
            ddns = ddns_enabled == "1"
        },
        status = {
            thinkcy = check_service("thinkcy"),
            clash = check_service("clash"),
            vpn = check_service("openvpn"),
            ddns = check_service("ddns")
        },
        timestamp = os.time(),
        hostname = sys.hostname(),
        uptime = sys.uptime()
    }
    
    -- Return JSON for AJAX requests
    if http.formvalue("ajax") then
        http.prepare_content("application/json")
        http.write_json(data)
        return
    end
    
    -- Render HTML template
    luci.template.render("thinkcy/view", data)
end

function action_log()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local logfile = "/var/log/thinkcy.log"
    local lines = tonumber(http.formvalue("lines") or "50")
    
    if http.formvalue("ajax") then
        http.prepare_content("text/plain")
        
        if fs.access(logfile) then
            local handle = io.popen(string.format("tail -n %d %s", lines, logfile))
            local content = handle:read("*a") or "Log file is empty"
            handle:close()
            http.write(content)
        else
            http.write("Log file not found")
        end
        return
    end
    
    luci.template.render("thinkcy/log", {
        logfile = logfile,
        default_lines = lines
    })
end

function action_system_info()
    local http = require "luci.http"
    local sys = require "luci.sys"
    local util = require "luci.util"
    
    if http.formvalue("ajax") then
        local info = {
            hostname = sys.hostname(),
            uptime = sys.uptime(),
            loadavg = sys.loadavg(),
            memory = sys.sysinfo(),
            time = os.date("%Y-%m-%d %H:%M:%S"),
            model = util.exec("cat /tmp/sysinfo/model 2>/dev/null || echo 'Unknown'"),
            version = util.exec("cat /etc/openwrt_release 2>/dev/null | grep 'DISTRIB_DESCRIPTION' | cut -d'=' -f2 | tr -d '\"'")
        }
        
        http.prepare_content("application/json")
        http.write_json(info)
        return
    end
    
    luci.template.render("thinkcy/system")
end

function action_apply()
    local http = require "luci.http"
    local sys = require "luci.sys"
    
    -- Apply ThinkCy service changes
    sys.call("/etc/init.d/thinkcy reload >/dev/null 2>&1")
    
    http.status(200, "OK")
    http.prepare_content("text/plain")
    http.write("Configuration applied successfully")
end
