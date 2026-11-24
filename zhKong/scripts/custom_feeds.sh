# --当前执行步骤：custom_feeds自定义软件包-1-调整订阅-1.1-通用软件包
../scripts/add_package_part1_before_feeds_update-add_feeds.sh

# 1-调整订阅-1.2-特定软件源

echo '--当前执行步骤：custom_feeds自定义软件包-1-调整订阅-1.3-更新软件源索引信息'
./scripts/feeds update -a

# --当前执行步骤：custom_feeds自定义软件包-2-调整源码
../scripts/add_package_part2_after_feeds_update-modify_sources.sh

echo "---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.3-仓库特定源码补丁$REPO_NAME.patch*.sh"
  # 规范化仓库名称（将斜杠转换为点）
  REPO_NAME=$(echo "$OP_REPO" | sed 's|/|.|g')
  PATCH_DIR="../$REPO_TYPE/scripts"
  
  # 检查目录是否存在，并安全查找补丁文件
  if [ -d "$PATCH_DIR" ]; then
    # 使用 find 替代 ls，配合 -print0 和 read 或直接安全遍历
    found_patches=0
    for patch in "$PATCH_DIR"/"$REPO_NAME".patch*.sh; do
      # 确保文件真实存在（防止没有匹配时通配符未被展开原样输出）
      [ -f "$patch" ] || continue    
      echo "----仓库补丁：应用$OP_REPO相关补丁: $patch"
      . "$patch"
      found_patches=1
    done
    
    if [ "$found_patches" -eq 0 ]; then
      echo "----仓库补丁：未发现$OP_REPO相关补丁。"
    fi
  else
    echo "----仓库补丁：目录 $PATCH_DIR 不存在，跳过。"
  fi

echo '--当前执行步骤：custom_feeds自定义软件包-3--安装feeds-./scripts/feeds install'
./scripts/feeds install -a

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig

#tree -L 3 ./feeds/
#tree -L 3 ./package/

#tree -L 3 ./feeds/ > tree_feeds.txt
#tree -L 3 ./package/ > tree_package.txt
