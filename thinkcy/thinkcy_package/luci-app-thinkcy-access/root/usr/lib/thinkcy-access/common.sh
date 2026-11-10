#!/bin/sh

TABLE="inet fw4"
SET_NAME="thinkcy_access_allow"

init_nft_set() {
    if ! nft list set $TABLE $SET_NAME >/dev/null 2>&1; then
        nft add set $TABLE $SET_NAME '{ type ether_addr; flags timeout; }'
    fi

    if ! nft list chain $TABLE forward | grep -q "@$SET_NAME"; then
        nft insert rule $TABLE forward ether saddr "@$SET_NAME" accept
    fi
}

clean_mac() {
    echo "$1" | tr -d ':' | tr '[:lower:]' '[:upper:]'
}
