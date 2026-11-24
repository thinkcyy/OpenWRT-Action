echo "-步骤：custom_feeds自定义软件包-0-$(basename "$0")"

# 1-调整订阅-1.1-通用软件源
../scripts/add_package_part1_before_feeds_update-add_feeds.sh

# 1-调整订阅-1.2-特定软件源

echo '--当前执行步骤：custom_feeds自定义软件包-1-调整订阅-1.3-更新软件源索引信息'
./scripts/feeds update -a

# 2-调整源码-2.1-通用软件源码
../scripts/add_package_part2_after_feeds_update-modify_sources.sh

# 2-调整源码-2.2-特定软件源码
# 规范化仓库名称（将斜杠转换为点）
echo OP_REPO为$OP_REPO

REPO_NAME=$(echo "$OP_REPO" | sed 's|/|.|g')
PATCH_DIR="../$REPO_TYPE/scripts"
echo REPO_NAME为：$REPO_NAME
echo 补丁目录为$PATCH_DIR
echo 所有文件：$(ls $PATCH_DIR)


# 检查目录是否存在，并安全查找补丁文件
if [ -d "$PATCH_DIR" ]; then
  # 使用 find 替代 ls，配合 -print0 和 read 或直接安全遍历
  found_patches=0
  for patch in "$PATCH_DIR"/"$REPO_NAME".patch*.sh; do
    # 确保文件真实存在（防止没有匹配时通配符未被展开原样输出）
    [ -f "$patch" ] || continue
    
    echo "发现仓库相关补丁: $patch"
    # 执行补丁
    #建议：如果补丁脚本不需要污染当前环境变量，用 . 运行即可，或者严格审查其内容
    . "$patch"
    found_patches=1
  done
  
  if [ "$found_patches" -eq 0 ]; then
    echo "未发现相关补丁。"
  fi
else
  echo "提示: 补丁目录 $PATCH_DIR 不存在，跳过。"
fi

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
