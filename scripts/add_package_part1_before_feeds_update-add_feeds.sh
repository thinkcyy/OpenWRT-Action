echo "--当前执行步骤：添加通用软件包-调整feeds-add_package_part1_before_feeds_update-add_feeds.sh"

echo '---添加额外feed源'
# luci-mod-status-nss
echo "src-git thinkcy_qosmio https://github.com/qosmio/packages-extra" | cat - feeds.conf.default                                                     > feeds.conf.add
# zerotier
cp feeds.conf.add feeds.conf.last ; echo "src-git thinkcy_mwarning https://github.com/mwarning/zerotier-openwrt.git" | cat - feeds.conf.last          > feeds.conf.add
cp feeds.conf.add feeds.conf.default
