#!/bin/sh -eux

mkdir -p /tmp/parallels;
ARCH="$(uname -m)"

if [ "${ARCH}" = "aarch64" ] ; then
  mount -o loop /tmp/prl-tools-lin-arm.iso /tmp/parallels;
else
  mount -o loop /tmp/prl-tools-lin.iso /tmp/parallels;
fi

VER="$(cat /tmp/parallels/version)";
echo "Parallels Tools Version: ${VER}";

/tmp/parallels/install --install-unattended-with-deps \
  || (code="$?"; \
    echo "Parallels tools installation exited ${code}, attempting" \
    "to output /var/log/parallels-tools-install.log"; \
    cat /var/log/parallels-tools-install.log; \
    exit "${code}");
umount /tmp/parallels;
rm -rf /tmp/parallels;
rm -f /tmp/*.iso;