#! /bin/sh
# kick.start alpine-setup; https://www.skreutz.com/posts/unattended-installation-of-alpine-linux/

set -o errexit
set -o nounset

# uncomment to shutdown on completion.
#trap 'poweroff' EXIT INT

# no stdin
exec 0<&-

# run this only once
rm -f /etc/local.d/auto-setup-alpine.start
rm -f /etc/runlevels/default/local

timeout 300 setup-alpine -ef /etc/auto-setup-alpine/answers
rm -rf /etc/auto-setup-alpine

# no password auth
sed -i -e 's/^root:x:/root:*:/' -e 's/^stefan:x:/stefan:*:/' /etc/passwd
sed -i -e 's/^root:[^:]*/root:*/' -e 's/^stefan:[^:]*/stefan:*/' /etc/shadow

apk update
apk upgrade
apk add man-pages mandoc mandoc-apropos docs

cat >/etc/doas.d/site.conf <<EOF
permit nopass :wheel
permit nopass keepenv root
EOF

# uncomment for sys install.
#sed -i -e 's/relatime/noatime/' /etc/fstab