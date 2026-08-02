# Dummy FRPC package

Purpose:

- Package name: frpc
- Architecture: all
- Installs no files
- Used only to satisfy luci-app-frpc dependency

Build:

```bash
make package/frpc/{clean,compile} V=s
```

Generated package:

```
bin/packages/*/*/frpc_9999-r99_all.apk
```

Install:

Copy the apk into your ImageBuilder local repository and regenerate APKINDEX.

```
