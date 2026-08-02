include $(TOPDIR)/rules.mk

PKG_NAME:=frpc
PKG_VERSION:=9999
PKG_RELEASE:=99

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Your Name <you@example.com>

include $(INCLUDE_DIR)/package.mk

define Package/frpc
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Dummy FRPC package
  URL:=https://github.com/fatedier/frp
  PKGARCH:=all
endef

define Package/frpc/description
 Dummy package used to satisfy dependencies of luci-app-frpc.

 This package intentionally installs no files.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/frpc/install
	# Intentionally empty
endef

$(eval $(call BuildPackage,frpc))
