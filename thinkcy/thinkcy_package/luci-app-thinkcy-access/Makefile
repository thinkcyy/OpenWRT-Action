include $(TOPDIR)/rules.mk

LUCI_TITLE:=上网管控
LUCI_DEPENDS:=+firewall4 +rpcd +jsonfilter
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-thinkcy-access
PKG_VERSION:=2.22.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-thinkcy-access
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=上网管控
  DEPENDS:=+firewall4 +rpcd +jsonfilter
endef

define Build/Compile
endef

define Package/luci-app-thinkcy-access/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/thinkcy-access $(1)/etc/config/thinkcy-access

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/thinkcy-access $(1)/etc/init.d/thinkcy-access

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./root/etc/hotplug.d/iface/95-thinkcy-access $(1)/etc/hotplug.d/iface/95-thinkcy-access

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./root/usr/sbin/thinkcy-access-refresh $(1)/usr/sbin/thinkcy-access-refresh
	$(INSTALL_BIN) ./root/usr/sbin/thinkcy-access-scheduler $(1)/usr/sbin/thinkcy-access-scheduler

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/thinkcy_access $(1)/usr/libexec/rpcd/thinkcy_access

	$(INSTALL_DIR) $(1)/usr/lib/thinkcy-access
	$(INSTALL_DATA) ./root/usr/lib/thinkcy-access/common.sh $(1)/usr/lib/thinkcy-access/common.sh

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-thinkcy-access.json $(1)/usr/share/luci/menu.d/luci-app-thinkcy-access.json

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-thinkcy-access.json $(1)/usr/share/rpcd/acl.d/luci-app-thinkcy-access.json

	$(INSTALL_DIR) $(1)/usr/share/luci/resources/view/thinkcy-access
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/thinkcy-access/main.js $(1)/usr/share/luci/resources/view/thinkcy-access/main.js

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	ln -sf /usr/share/luci/resources/view/thinkcy-access $(1)/www/luci-static/resources/view/thinkcy-access
endef

$(eval $(call BuildPackage,luci-app-thinkcy-access))
