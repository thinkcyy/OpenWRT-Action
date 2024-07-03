echo "-当前执行步骤：锁定已下载feeds目录日期"

FEED_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REV_HASH=$(git rev-list -n 1 --before=${REV_DATE} ${FEED_BRANCH})
PWD=$(pwd)
echo --拟切换$PWD至HASH：$REV_HASH
git checkout $REV_HASH
