---
layout: post
title:  "Install Debian Testing in Intel NUC (DN2820FYKH)"
date:   2016-05-01 18:43:00
categories: blog
---

Recently had to install a custom flavour of Debian Testing (current codename 'stretch') on my Intel NUC DN2820FYKH. The installation was straight forward. Booting it, wasn't...

On booting to a freshly installed system, I got a black screen. After a google search, this seems to be quite frequent on a variety of NUCs. One interesting page, [01.org](https://01.org/linuxgraphics/forum/graphics-installer-discussions/nuc5i3ryh-black-screen-debian) suggested to add `i915.modeset=0` or `acpi=off` on your Grub. This actually fixed the black screen issue but two others emerged:

- CPU was rendering graphics which was pretty slow (`glxinfo | grep OpenGL` output string `llvmpipe`)
- Screen resolution wasn't the correct one. `arandr` listed only one resolution.

## Configure Xorg

After checking for errors and warnings on my `/var/log/Xorg.0.log`, had to install all this:

```
apt-get install mesa-utils
apt-get install xserver-xorg-video-intel
apt-get install libgl1-mesa
apt-get install libgl1-mesa-dri
apt-get install libdrm-intel1 libdrm2
```

Confirm with `glxinfo | grep OpenGL` that you're not rendering with your CPU.

## Downgrade to kernel 3.x.xx

Still, screen resolution wasn't fixed. On [01.org - NUC5I3RYH - BLACK SCREEN - DEBIAN](https://01.org/linuxgraphics/forum/graphics-installer-discussions/nuc5i3ryh-black-screen-debian), [one comment](https://01.org/comment/2336#comment-2336) hinted that a previous kernel version actually works. Tried to downgrade to jessies kernel and finally had my NUC displaying the correct resolution.

```
# Go to stable (currently jessie)
sed -i.original s/stretch/jessie/g /etc/apt/sources.list
apt-get update

# Find suited kernel package 
apt-cache search linux-image

# Find suited kernel version ("Candidate" field)
apt-cache policy linux-image-3.16.0-4-amd64

# Install kernel image & headers
apt-get install linux-image-3.16.0-4-amd64=3.16.7-ckt25-1
apt-get install linux-headers-3.16.0-4-amd64=3.16.7-ckt25-1

# Fix kernel version (avoid update to 4.x.x)
apt-mark hold linux-headers-3.16.0-4-amd64
apt-mark hold linux-image-3.16.0-4-amd64

# Back to Testing
mv /etc/apt/sources.list.original /etc/apt/sources.list


# Update Grub (really good instructions okturtles reference)
vim /boot/grub/grub.cfg 
vim /etc/default/grub 
grub-update
vim /etc/default/grub 
grub-update
```

If you don't have `grub-update`, you can simply create one:

```
cat <<'EOF' > /usr/sbin/update-grub
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
EOF
chmod +x  /usr/sbin/update-grub
```

### References

- Configure Xorg
  - https://wiki.debian.org/Mesa
- Downgrade kernel
  - https://01.org/comment/2336#comment-2336
  - https://blog.okturtles.com/2014/06/how-to-downgrade-a-linux-kernel-on-debian/
  - http://askubuntu.com/questions/331538/what-is-the-right-way-to-downgrade-kernel
  - http://askubuntu.com/questions/418666/update-grub-command-not-found

