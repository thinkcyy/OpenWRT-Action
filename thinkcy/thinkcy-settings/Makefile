# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2021 Lean <coolsnowwolf@gmail.com>
# Copyright (C) 2021-2024 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=thinkcy-settings
PKG_RELEASE:=30

PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/thinkcy-settings
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI support for thinkcy Settings
  DEPENDS:=+luci
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/thinkcy-settings/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/99-thinkcy-settings $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,thinkcy-settings))
