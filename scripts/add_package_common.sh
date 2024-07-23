echo "-当前执行步骤：添加通用软件包"

[[ -d "package/thinkcy" ]] && mkdir -p package/thinkcy
git clone https://github.com/izilzty/luci-app-temp-status ./package/thinkcy/luci-app-temp-status
