echo "-步骤：custom_feeds自定义软件包-0-$(basename "$0")"

# 1-调整订阅-1.1-通用软件源
../scripts/add_package_part1_before_feeds_update-add_feeds.sh

# 1-调整订阅-1.2-特定软件源

echo '--当前执行步骤：custom_feeds自定义软件包-1-调整订阅-1.3-更新软件源索引信息'
./scripts/feeds update -a

# 2-调整源码-2.1-通用软件源码
../scripts/add_package_part2_after_feeds_update-modify_sources.sh

# 2-调整源码-2.2-特定软件源码

./scripts/feeds install -a

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig

tree -L 3 ./feeds/
tree -L 3 ./package/

tree -L 3 ./feeds/ > tree_feeds.txt
tree -L 3 ./package/ > tree_package.txt
