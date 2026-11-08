# luci-app-thinkcy-access 1.0.0

LuCI application for OpenWrt 25.12 SDK.

## Features
- Only explicitly registered MAC addresses are controlled (方案 A); all other clients are unaffected.
- Registered clients are denied routed traffic leaving `br-lan` unless temporarily authorized.
- LAN-local traffic and traffic to the router itself are not blocked by the forward hook.
- nftables timeout automatically expires each authorization.
- DHCPv4 lease discovery plus manual MAC/name registration.
- Last selected MAC and duration are stored and restored when the page is opened.
- Duration range: 1 to 10080 minutes.

## Build
Copy this directory into the SDK tree, e.g. `package/luci-app-thinkcy-access/`, then run:
```sh
make package/luci-app-thinkcy-access/compile V=s
```
Ensure LuCI feeds are installed and package `luci-app-thinkcy-access` is selected if required.

## Install / activate
Install the generated package, then:
```sh
/etc/init.d/firewall restart
/etc/init.d/thinkcy-access enable
/etc/init.d/thinkcy-access restart
```

## Important assumptions
The first implementation treats `br-lan` as the LAN interface and any forwarded egress interface other than `br-lan` as external. If the router has routed internal VLANs or other internal L3 interfaces, adjust the `oifname != "br-lan"` condition to exclude them as well. For the common LAN -> PPPoE WAN path (e.g. `pppoe-CT`) this matches the WAN egress.

The app discovers DHCPv4 leases via `ubus call dhcp ipv4leases`. DHCPv6-only or static devices can be entered manually. A device must be registered in the Managed devices list before it is restricted. Removing it immediately removes it from management.

Test with one device first. Confirm actual interface names and nftables rule placement before deploying broadly:
```sh
nft list table inet fw4
nft list set inet fw4 thinkcy_managed_macs
nft list set inet fw4 thinkcy_allowed_macs
```

This is an initial source release. The page's action endpoint is protected by the LuCI admin route/session, but before production deployment verify the exact LuCI revision's CSRF handling and test with a non-admin session. On firewall reload, the persistent managed list is rebuilt; active temporary grants may be cleared and must be re-issued.
