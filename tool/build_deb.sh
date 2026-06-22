#!/bin/bash
set -euo pipefail

BUNDLE_DIR="build/linux/x64/release/bundle"
DEB_BUILD="build/linux/deb"
PKG_NAME="point-machine"
APP_ID="tech.hammerhead.point_machine"
VERSION="1.0.0"
ARCH="amd64"
INSTALL_DIR="/opt/point-machine"

rm -rf "$DEB_BUILD"
mkdir -p "$DEB_BUILD/DEBIAN"
mkdir -p "$DEB_BUILD/$INSTALL_DIR"
mkdir -p "$DEB_BUILD/usr/share/applications"
mkdir -p "$DEB_BUILD/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$DEB_BUILD/usr/bin"

cp -r "$BUNDLE_DIR/point_machine" "$DEB_BUILD/$INSTALL_DIR/"
cp -r "$BUNDLE_DIR/lib" "$DEB_BUILD/$INSTALL_DIR/"
cp -r "$BUNDLE_DIR/data" "$DEB_BUILD/$INSTALL_DIR/"

cp assets/icon/orbit-1024.png "$DEB_BUILD/usr/share/icons/hicolor/512x512/apps/${APP_ID}.png"

cat > "$DEB_BUILD/usr/share/applications/${APP_ID}.desktop" << EOF
[Desktop Entry]
Name=Point Machine
Comment=Serverless peer-to-peer file synchronizer
Exec=${INSTALL_DIR}/point_machine
Icon=${APP_ID}
Terminal=false
Type=Application
Categories=Utility;Network;FileTransfer;
StartupWMClass=${APP_ID}
EOF

cat > "$DEB_BUILD/usr/bin/point-machine" << EOF
#!/bin/sh
exec ${INSTALL_DIR}/point_machine "\$@"
EOF
chmod 755 "$DEB_BUILD/usr/bin/point-machine"

cat > "$DEB_BUILD/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Architecture: ${ARCH}
Maintainer: Hammerhead <dev@hammerhead.tech>
Depends: libgtk-3-0, libglib2.0-0, liblzma5, libstdc++6
Description: Point Machine - Serverless peer-to-peer file synchronizer
 A Syncthing alternative. Files sync directly between a user's own devices
 with no server anywhere, including for discovery.
EOF

cat > "$DEB_BUILD/DEBIAN/postinst" << 'EOF'
#!/bin/sh
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
update-desktop-database /usr/share/applications || true
EOF
chmod 755 "$DEB_BUILD/DEBIAN/postinst"

cat > "$DEB_BUILD/DEBIAN/postrm" << 'EOF'
#!/bin/sh
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
update-desktop-database /usr/share/applications || true
EOF
chmod 755 "$DEB_BUILD/DEBIAN/postrm"

dpkg-deb --build "$DEB_BUILD" "build/${PKG_NAME}_${VERSION}_${ARCH}.deb"

echo "Built: build/${PKG_NAME}_${VERSION}_${ARCH}.deb"
echo "Install: sudo dpkg -i build/${PKG_NAME}_${VERSION}_${ARCH}.deb"
