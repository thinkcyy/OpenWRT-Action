#!/bin/sh
CFG=thinkcy-access
valid_mac() { printf '%s\n' "$1" | grep -Eiq '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'; }
norm_mac() { printf '%s' "$1" | tr 'A-F' 'a-f'; }
uint() { case "$1" in ''|*[!0-9]*) return 1;; esac; [ "$1" -ge "$2" ] 2>/dev/null && [ "$1" -le "$3" ] 2>/dev/null; }

cron_valid() {
  v="$1"; lo="$2"; hi="$3"; [ -n "$v" ] || return 1
  old="$IFS"; IFS=,; set -- $v; IFS="$old"
  for p in "$@"; do
    case "$p" in */*) b="${p%%/*}"; s="${p#*/}"; uint "$s" 1 "$((hi-lo+1))" || return 1;; *) b="$p"; s=1;; esac
    [ "$b" = "*" ] && continue
    case "$b" in *-*) a="${b%-*}"; z="${b#*-}"; uint "$a" "$lo" "$hi" && uint "$z" "$lo" "$hi" && [ "$a" -le "$z" ] || return 1;; *) uint "$b" "$lo" "$hi" || return 1;; esac
  done
}
cron_match() {
  val="$1"; f="$2"; lo="$3"; hi="$4"; [ "$f" = "*" ] && return 0
  old="$IFS"; IFS=,; set -- $f; IFS="$old"
  for p in "$@"; do
    case "$p" in */*) b="${p%%/*}"; st="${p#*/}";; *) b="$p"; st=1;; esac
    if [ "$b" = "*" ]; then a="$lo"; z="$hi"
    elif echo "$b" | grep -q '-'; then a="${b%-*}"; z="${b#*-}"
    else a="$b"; z="$b"; fi
    n="$a"; while [ "$n" -le "$z" ]; do [ "$n" -eq "$val" ] && return 0; n=$((n+st)); done
  done
  return 1
}

ensure_nft() {
  nft list table inet thinkcy_access >/dev/null 2>&1 && return 0
  nft add table inet thinkcy_access || return 1
  nft add set inet thinkcy_access managed_macs '{ type ether_addr; }' || return 1
  nft add set inet thinkcy_access allowed_macs '{ type ether_addr; flags timeout; }' || return 1
  nft add set inet thinkcy_access wan_ifaces '{ type ifname; }' || return 1
  nft add chain inet thinkcy_access forward '{ type filter hook forward priority -1; policy accept; }' || return 1
  nft add rule inet thinkcy_access forward oifname @wan_ifaces ether saddr @managed_macs ether saddr != @allowed_macs counter drop
}
sync_managed() {
  ensure_nft || return 1
  nft flush set inet thinkcy_access managed_macs 2>/dev/null
  i=0
  while uci -q get "$CFG.@device[$i]" >/dev/null 2>&1; do
    m="$(uci -q get "$CFG.@device[$i].mac")"
    valid_mac "$m" && nft add element inet thinkcy_access managed_macs "{ $(norm_mac "$m") }" 2>/dev/null
    i=$((i+1))
  done
  refresh_wan
}
refresh_wan() {
  zone="$(uci -q get "$CFG.@settings[0].wan_zone")"; [ -n "$zone" ] || zone=wan
  nft flush set inet thinkcy_access wan_ifaces 2>/dev/null
  i=0
  while uci -q get "firewall.@zone[$i]" >/dev/null 2>&1; do
    [ "$(uci -q get "firewall.@zone[$i].name")" = "$zone" ] || { i=$((i+1)); continue; }
    for net in $(uci -q get "firewall.@zone[$i].network"); do
      st="$(ubus -S call "network.interface.$net" status 2>/dev/null)"
      dev="$(printf '%s' "$st" | jsonfilter -e '@.l3_device' 2>/dev/null | head -n1)"
      [ -n "$dev" ] || dev="$(printf '%s' "$st" | jsonfilter -e '@.device' 2>/dev/null | head -n1)"
      case "$dev" in ''|*[!A-Za-z0-9_.:@-]*) continue;; esac
      nft add element inet thinkcy_access wan_ifaces "{ \"$dev\" }" 2>/dev/null
    done
    i=$((i+1))
  done
}
grant_mac() {
  m="$(norm_mac "$1")"; d="$2"; valid_mac "$m" && uint "$d" 1 10080 || return 1
  ensure_nft || return 1
  nft delete element inet thinkcy_access allowed_macs "{ $m }" 2>/dev/null
  nft add element inet thinkcy_access allowed_macs "{ $m timeout ${d}m }" || return 1
  uci set "$CFG.@settings[0].last_mac=$m"; uci set "$CFG.@settings[0].last_minutes=$d"; uci commit "$CFG"
}
add_device() {
  m="$(norm_mac "$1")"; valid_mac "$m" || return 1
  i=0; while uci -q get "$CFG.@device[$i]" >/dev/null 2>&1; do
    [ "$(norm_mac "$(uci -q get "$CFG.@device[$i].mac")")" = "$m" ] && { sync_managed; return 0; }
    i=$((i+1))
  done
  uci add "$CFG" device >/dev/null; uci set "$CFG.@device[-1].mac=$m"; uci commit "$CFG"; sync_managed
}
remove_device() {
  m="$(norm_mac "$1")"; valid_mac "$m" || return 1
  i=0; while uci -q get "$CFG.@device[$i]" >/dev/null 2>&1; do
    [ "$(norm_mac "$(uci -q get "$CFG.@device[$i].mac")")" = "$m" ] && { uci delete "$CFG.@device[$i]"; break; }
    i=$((i+1))
  done
  uci commit "$CFG"; ensure_nft
  nft delete element inet thinkcy_access managed_macs "{ $m }" 2>/dev/null
  nft delete element inet thinkcy_access allowed_macs "{ $m }" 2>/dev/null
}
