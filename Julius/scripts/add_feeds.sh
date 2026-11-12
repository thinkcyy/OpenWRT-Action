echo "-添加额外feed源：$0"
echo "src-git nss https://github.com/JuliusBairaktaris/nss-packages.git;ppe-nss" >> ./feeds.conf.default
sed -i 's|^src-git luci .*|src-git luci https://github.com/JuliusBairaktaris/luci.git;luci-app-ppe-qos|' feeds.conf.default
