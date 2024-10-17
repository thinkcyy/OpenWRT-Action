lock_date() {
        cd feeds/$FEED_ID
        FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        REV_HASH=$(git rev-list -n 1 --before=${REV_DATE} ${FEED_BRANCH})
        echo $FEED_ID对应的HASH为：$REV_HASH
        cd ../..
        sed  -i -e "/\s${FEED_ID}\s.*\.git$/s/$/^${REV_HASH}/" feeds.conf 
        if [  -n "$2" ] ;then
                sed -n '/${FEED_ID}/p' feeds.conf >> feeds-locked.conf
                cp feeds-locked.conf feeds.conf
        fi
}

sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf        
sed -i "/^\#/d" feeds.conf

if [  -n "$2" ] ;then
        echo "--当前执行步骤：锁定$2日期"
        cp feeds.conf feeds-locked.conf
        sed -i -e "/$2/d" feeds-locked.conf        
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
    else
      continue  
    fi
  else
    lock_date
  fi
done
