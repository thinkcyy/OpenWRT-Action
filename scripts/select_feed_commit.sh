#!/bin/sh

lock_date() {
    echo ">>> 锁定 feed: $FEED_ID"

    # 获取当前分支，若 HEAD 分离则使用 HEAD
    FEED_BRANCH=$(
        git -C "feeds/$FEED_ID" symbolic-ref --quiet --short HEAD 2>/dev/null \
        || echo HEAD
    )

    # 查找指定日期之前最后一次提交
    REV_HASH=$(
        git -C "feeds/$FEED_ID" \
            rev-list -n 1 \
            --before="$REV_DATE" \
            "$FEED_BRANCH" 2>/dev/null
    )

    if [ -z "$REV_HASH" ]; then
        echo "ERROR: $FEED_ID 在 $REV_DATE 之前没有任何提交。"
        return 1
    fi

    echo "$FEED_ID 对应 HASH：$REV_HASH"

    # 删除已有 ^hash（避免重复追加）
    sed -i "/^[^#].*[[:space:]]$FEED_ID[[:space:]]/s/\^[0-9a-f]\{40\}$//" feeds.conf

    # 在对应 feed 后追加 hash
    sed -i "/^[^#].*[[:space:]]$FEED_ID[[:space:]]/s|\$|^$REV_HASH|" feeds.conf
}

###############################################################################
# 初始化 feeds.conf
###############################################################################

if [ -n "$2" ]; then
    echo "-- 当前执行步骤：重新锁定 $2"

    cp feeds.conf feeds-locked.conf

    # 删除上一轮该 feed
    sed -i "/^[^#].*[[:space:]]$2[[:space:]]/d" feeds-locked.conf

    # 恢复为原始 feeds.conf
    sed 's/^src-git[^[:space:]]*/src-git-full/' feeds.conf.default > feeds.conf

else
    echo "-- 当前执行步骤：锁定全部 feeds"

    sed 's/^src-git[^[:space:]]*/src-git-full/' feeds.conf.default > feeds.conf

    ./scripts/feeds update -a || exit 1
fi

# 删除注释
sed -i '/^#/d' feeds.conf

###############################################################################
# 日期
###############################################################################

if [ -n "$1" ]; then
    REV_DATE="$1"
else
    REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi

echo "锁定日期：$REV_DATE"

###############################################################################
# 规范 feeds.conf
###############################################################################

# 删除 branch 标记（如 ;openwrt-25.05）
sed -i 's/;.*$//' feeds.conf

# 删除已有 ^hash
sed -i 's/\^[0-9a-f]\{40\}$//' feeds.conf

# 保证 URL 只有一个 .git
sed -i 's/\.git$//' feeds.conf
sed -i 's/$/.git/' feeds.conf

###############################################################################
# 遍历 feed
###############################################################################

while read -r FEED_ID
do
    [ -z "$FEED_ID" ] && continue

    if [ -n "$2" ]; then

        [ "$FEED_ID" != "$2" ] && continue

        lock_date || exit 1

        sed -n "/^[^#].*[[:space:]]$FEED_ID[[:space:]]/p" feeds.conf \
            >> feeds-locked.conf

        mv feeds-locked.conf feeds.conf

        echo
        echo "新的 feeds.conf："
        cat feeds.conf

        exit 0
    else
        lock_date || exit 1
    fi

done <<EOF
$(sed -n '/^src-git[^[:space:]]*[[:space:]]/{s///;s/[[:space:]].*$//;p}' feeds.conf)
EOF
