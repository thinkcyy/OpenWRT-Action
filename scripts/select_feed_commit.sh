echo "-当前执行步骤：锁定feeds日期"
sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf
sed -i "/^\#/d" feeds.conf
./scripts/feeds update -a
if [  -n "$1" ] ;then
  REV_DATE=$1
else
  REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi
echo "选定的日期为：$REV_DATE"
sed -e "/^src-git\S*\s/{s///;s/\s.*$//p}" feeds.conf  | while read -r FEED_ID
do
cd feeds/$FEED_ID
FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REV_HASH=$(git rev-list -n 1 --before=${REV_DATE} ${FEED_BRANCH})
echo $FEED_ID对应的HASH为：$REV_HASH
sed -i -e "/\s${FEED_ID}\s.*\.git$/s/$/^${REV_HASH}/" feeds.conf
cd ../..
done
