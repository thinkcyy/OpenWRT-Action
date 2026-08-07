#!/bin/bash

# 1. 初始化回溯时间（如果没传参数1，则使用当前主仓库最新的提交时间）
if [ -n "$1" ] ;then
        REV_DATE="$1"
else
        REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi
echo "选定的回溯截止日期为：$REV_DATE"

# 2. 如果是单仓锁定，先为上一轮打标成果做备份
if [ -n "$2" ] ;then
        echo "-- 当前执行步骤：单仓锁定 [$2] 日期"
        echo "保留上一轮打标成果为 feeds-locked.conf"
        cp feeds.conf feeds-locked.conf        
        # 移除上一轮打标中关于目标 feed 的那一行，防止重复
        sed -i -e "/\s$2\s/d" feeds-locked.conf 
fi

# 3. 剥离并清理 feeds.conf 中现存的所有 ^hash 标记（防止 update 时 Git 误建分支）
# 这一步是解决 "ambiguous" 警告的核心！
if [ -f "feeds.conf" ]; then
        echo "正在清理 feeds.conf 中历史残留的脱字符标记..."
        sed -i -e 's/\^[a-fA-F0-9]\{40\}//g' feeds.conf
fi

# 4. 执行同步更新（确保本地 feeds/ 目录有最新的 git 提交历史供回溯查询）
if [ -z "$2" ] ;then
        echo "-- 当前执行步骤：全量锁定所有 feeds 日期"
        # 全量锁定时，如果 feeds.conf 不存在或为空，则从默认配置恢复
        [ ! -s "feeds.conf" ] && cp feeds.conf.default feeds.conf
        sed -i "/^\#/d" feeds.conf
        ./scripts/feeds update -a
fi

lock_date() {
        local FEED_DIR="feeds/$FEED_ID"
        if [ ! -d "$FEED_DIR" ]; then
                echo "警告: 目录 $FEED_DIR 不存在，跳过打标。"
                return
        fi
        
        cd "$FEED_DIR" || return
        # 获取该 feed 当前的本地分支名
        local FEED_BRANCH
        FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        # 根据指定的日期，回溯寻找那个时间点之前的最新一条 Commit Hash
        local REV_HASH
        REV_HASH=$(git rev-list -n 1 --before="${REV_DATE}" "${FEED_BRANCH}")
        echo ">>> ${FEED_ID} 在 ${REV_DATE} 对应的 HASH 为：${REV_HASH}"
        cd ../..
        
        if [ -n "$REV_HASH" ]; then
                # 核心改进：精准匹配该行末尾，打上 ^hash 标记
                sed -i -e "/\s${FEED_ID}\s/s/$/^${REV_HASH}/" feeds.conf
        else
                echo "错误: 未能获取到 ${FEED_ID} 的有效 HASH！"
        fi
}

# 5. 遍历 feeds.conf 逐个打标锁定
# 正则说明：兼容末尾可能带有或不带有 ^hash 的情况，精准提取第二列的 FEED_ID
sed -n -e 's/^src-git\s\+\(\S\+\)\s.*/\1/p' feeds.conf | while read -r FEED_ID
do
        if [ -n "$2" ] ;then
                # 单仓锁定逻辑
                if [ "$FEED_ID" = "$2" ] ;then  
                        lock_date
                        echo ">>> $FEED_ID 单仓新打标结果："
                        sed -n "/\s${FEED_ID}\s/p" feeds.conf
                        
                        # 将这个新打标的行，追加到上一轮的备份成果中
                        sed -n "/\s${FEED_ID}\s/p" feeds.conf >> feeds-locked.conf
                        cp feeds-locked.conf feeds.conf
                        break
                fi
        else
                # 全量锁定逻辑
                lock_date
        fi
done

echo ">>> 最终生成的 feeds.conf 内容如下："
cat feeds.conf
