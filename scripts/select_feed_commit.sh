echo "当前执行步骤：选择feeds日期"
sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf
sed -i "/^\#/d" feeds.conf
./scripts/feeds update -a
if [ ! -n "$1" ] ;then
  REV_DATE=$1
else
  REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)
fi
echo "选定的日期为：$REV_DATE"
sed -e "/^src-git\S*\s/{s///;s/\s.*$//p}" feeds.conf  | while read -r FEED_ID
do
REV_HASH=$(git -C feeds/${FEED_ID} rev-list -n 1 --all --before=${REV_DATE})
echo $REV_HASH
sed -i -e "/\s${FEED_ID}\s.*\.git$/s/$/^${REV_HASH}/" feeds.conf
done
