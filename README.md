# wipi

**[work-in-progress]**

alpine for wipi02 - automated alpine boot using pre-boot and post-boot: kickstart and bootstrap!

downloads alpine, seeds configuration (user, hostname, timezone, packages), injects SSH pubkey, sets password, outputs tar ready to flash

## answer file by seed

build.sh creates image via Alpine installer seed answers:
- **hostname, timezone, keyboard layout** - via seed
- **user creation** (USERNAME from .env) - via seed, with wheel group (sudo)
- **user password** (USER_PASSWD from .env) - injected for console/sudo access
- **packages** - openssh, docker, docker-compose, curl, git - via seed
- **SSH public key** - injected to USERNAME's ~/.ssh/authorized_keys for remote login
- **network** - DHCP on eth0, DNS to 1.1.1.1 - via seed
- ...

no interactive setup - boots directly to prompt with user configured

## auth

- **remote access (SSH):** SSH public key (no password needed)
- **local console/sudo:** password required

## quick start

create `.env` from template and fill in values:

```bash
HOSTNAME=wipi
TIMEZONE=UTC
ALPINE_VER=3.23.3
ALPINE_ARCH=armhf
USERNAME=pi
USER_PASSWD=
WIFI_SSID=
WIFI_PASSWD=
SSH_PUBKEY="ssh-rsa AAAA...public-key-here..."
```

build:

```bash
./build.sh
```

outputs: `.build/alpine-wipi.tar.gz` ready to flash

## flash to sd card

mount sd card, extract tar:

```bash
mount /dev/sdX /media/user/ALPINE
tar -xzf build/alpine-wipi.tar.gz -C /media/user/ALPINE
sync
umount /media/user/ALPINE
```

## first boot

insert sd card, power on pi, wait 2-3 minutes

alpine boots preconfigured with:
- hostname set
- user (USERNAME) created with SSH pubkey
- packages installed
- docker ready
