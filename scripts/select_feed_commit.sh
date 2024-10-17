lock_date() {
        cd feeds/$FEED_ID
        #获取分支和HASH
        FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        REV_HASH=$(git rev-list -n 1 --before=${REV_DATE} ${FEED_BRANCH})
        echo $FEED_ID对应的HASH为：$REV_HASH
        cd ../..
        #打标
        sed -i -e "/\s${FEED_ID}\s.*\.git$/s/$/^${REV_HASH}/" feeds.conf
}

if [  -n "$2" ] ;then
        echo "--当前执行步骤：锁定$2日期"
        echo 保留上一轮打标成果为feeds-locked.conf
        cp feeds.conf feeds-locked.conf        
        cat feeds-locked.conf
        #移除上一轮打标成果中的目标feed
        sed -i -e "/$2/d" feeds-locked.conf 
        #重新初始化feed为全量链接
        sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf       
        sed -i "/^\#/d" feeds.conf
else
        echo "-当前执行步骤：锁定feeds日期"
        sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf        
        sed -i "/^\#/d" feeds.conf
        ./scripts/feeds update -a
fi

if [  -n "$1" ] ;then
  REV_DATE=$1
else
  REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi
echo "选定的日期为：$REV_DATE"

#删除分支标记
sed -i -e "s/\;.*$//g" feeds.conf
#添加.git后缀
sed -i "s/\.git//g" feeds.conf
sed -i "s/$/\.git/g" feeds.conf

sed -e "/^src-git\S*\s/{s///;s/\s.*$//p}" feeds.conf  | while read -r FEED_ID
do
  if [  -n "$2" ] ;then
    if [  "$FEED_ID" = "$2" ] ;then  
      lock_date
      #在上一轮打标成果基础上添加该仓库hash                    
      echo $2打标结果
      sed '/${2}/p' feeds.conf
      sed -n '/${2}/p' feeds.conf >> feeds-locked.conf
      cp feeds-locked.conf feeds.conf
      echo $2打标后fedds.conf为
      cat feeds.conf    
      break
    else
      continue  
    fi
  else
    lock_date
  fi
done
