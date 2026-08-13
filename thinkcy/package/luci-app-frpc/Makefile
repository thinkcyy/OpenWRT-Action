include $(TOPDIR)/rules.mk

PKG_VERSION:=20260812
PKG_RELEASE:=9
PKG_NAME:=luci-app-frpc

# 高版本24.10.4的sdk会增加依赖luci-lua-runtime导致低版本系统装不上ipk，建议22.03.7
LUCI_TITLE:=LuCI support for Frpc toml
LUCI_DEPENDS:=+libc +luci-compat +luci-lua-runtime +frpc
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/frpc
endef


# 安装后脚本，可以配置权限等但不建议
define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod 0755 /etc/init.d/frpc
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
