echo "--当前执行步骤：custom_feeds自定义软件包-1-调整订阅-1.1-通用软件包-$(basename "$0")"

# luci-mod-status-nss
echo "src-git thinkcy_qosmio https://github.com/qosmio/packages-extra" | cat - feeds.conf.default                                                     > feeds.conf.add
# zerotier
cp feeds.conf.add feeds.conf.last ; echo "src-git thinkcy_mwarning https://github.com/mwarning/zerotier-openwrt.git" | cat - feeds.conf.last          > feeds.conf.add
cp feeds.conf.add feeds.conf.default
