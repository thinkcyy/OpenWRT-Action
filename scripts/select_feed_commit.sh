#!/bin/bash

lock_date() {
        local FEED_DIR="feeds/$FEED_ID"
        if [ ! -d "$FEED_DIR" ]; then
                echo "警告: 目录 $FEED_DIR 不存在，跳过打标。"
                return
        fi
        
        cd "$FEED_DIR" || return
        # 获取当前分支名
        FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        # 核心：根据指定日期获取该分支当时的 Commit Hash
        REV_HASH=$(git rev-list -n 1 --before="${REV_DATE}" "${FEED_BRANCH}")
        echo ">>> ${FEED_ID} 在 ${REV_DATE} 对应的 HASH 为：${REV_HASH}"
        cd ../..
        
        if [ -n "$REV_HASH" ]; then
                # 使用 OpenWrt 标准的分号(;)进行追加锁定
                sed -i -e "/\s${FEED_ID}\s/s/$/;${REV_HASH}/" feeds.conf
        else
                echo "错误: 未能获取到 ${FEED_ID} 的有效 HASH！"
        fi
}

# 1. 初始化基础时间
if [ -n "$1" ] ;then
        REV_DATE="$1"
else
        REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi
echo "选定的回溯截止日期为：$REV_DATE"

# 2. 初始化 feeds.conf 结构 (不再暴力裁剪 URL)
if [ -n "$2" ] ;then
        echo "-- 当前执行步骤：单仓锁定 [$2] 日期"
        echo "保留上一轮打标成果为 feeds-locked.conf"
        cp feeds.conf feeds-locked.conf        
        sed -i -e "/\s$2\s/d" feeds-locked.conf 
        
        # 从默认配置恢复干净的基准线
        cp feeds.conf.default feeds.conf
        sed -i "/^\#/d" feeds.conf
else
        echo "-- 当前执行步骤：全量锁定 feeds 日期"
        cp feeds.conf.default feeds.conf
        sed -i "/^\#/d" feeds.conf
        # 确保本地有各 feed 仓库的 git 历史记录，否则无法获取旧 Hash
        ./scripts/feeds update -a
fi

# 3. 遍历并执行打标
# 正则说明：匹配 src-git 开头，并提取第二列的 FEED_ID
sed -n -e 's/^src-git\s\+\(\S\+\)\s.*/\1/p' feeds.conf | while read -r FEED_ID
do
        if [ -n "$2" ] ;then
                if [ "$FEED_ID" = "$2" ] ;then  
                        lock_date
                        echo ">>> $FEED_ID 单仓打标结果："
                        sed -n "/\s${FEED_ID}\s/p" feeds.conf
                        
                        # 合并到上一轮成果中
                        sed -n "/\s${FEED_ID}\s/p" feeds.conf >> feeds-locked.conf
                        cp feeds-locked.conf feeds.conf
                        break
                fi
        else
                lock_date
        fi
done

echo ">>> 最终生成的 feeds.conf 内容如下："
cat feeds.conf
