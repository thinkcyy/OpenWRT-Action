# luci-app-thinkcy-access 2.0.0

Lua-free LuCI application for OpenWrt 25.12. The frontend is a LuCI JavaScript view; backend RPC uses rpcd's documented executable-plugin interface (shell + jsonfilter/jshn), not Lua or ucode. This avoids the previously encountered ucode/Lua ABI issue.

Features: explicit MAC management; DHCP lease discovery; manual temporary grants; multiple cron-style scheduled grants; task listing/edit/enable/disable/delete; UCI persistence; temporary grants expire through nftables timeout sets; managed devices return to blocked state after reboot.

Build in OpenWrt 25.12 SDK after installing/updating the LuCI feed:
`make package/feeds/luci/luci-app-thinkcy-access/compile V=s`

No `luci-lua-runtime` or `ucode-mod-lua` dependency.

Important: configure the firewall zone name in `/etc/config/thinkcy-access` (default `wan`). WAN devices are resolved from that zone's logical networks. Test carefully with flow offloading enabled; established offloaded flows may bypass ordinary forwarding hooks. The source is not represented as compiled or tested on your router.
