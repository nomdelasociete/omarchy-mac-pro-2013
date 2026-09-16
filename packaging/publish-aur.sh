#!/bin/bash
# Push packaging/PKGBUILD to the AUR. Requires SSH key ~/.ssh/id_ed25519_aur
# added at https://aur.archlinux.org/account/
set -euo pipefail
cd "$(dirname "$0")"
PKG=nomdelasociete-macpro
AUR_DIR="${TMPDIR:-/tmp}/aur-$PKG"
rm -rf "$AUR_DIR"
git clone "ssh://aur@aur.archlinux.org/$PKG.git" "$AUR_DIR"
cp -f PKGBUILD .SRCINFO "$AUR_DIR/"
cd "$AUR_DIR"
git add PKGBUILD .SRCINFO
git -c user.email='65334819+jbronssin@users.noreply.github.com' \
    -c user.name='Jean-Baptiste Ronssin' \
    commit -m "nomdelasociete-macpro 0.4.0"
git push origin master
echo "https://aur.archlinux.org/packages/$PKG"
