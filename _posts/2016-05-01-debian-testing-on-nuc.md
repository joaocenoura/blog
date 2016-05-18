---
layout: post
title:  "Install Debian Testing in Intel NUC (DN2820FYKH)"
date:   2016-05-01 18:43:00
categories: [debian, intel nuc]
---

Recently had to install a custom flavour of Debian Testing (current codename 'stretch') on my Intel NUC DN2820FYKH. The installation was straight forward. Booting it, wasn't...

On booting to a freshly installed system, I got a black screen. After a google search, this seems to be quite frequent on a variety of NUCs. A bug ticket was opened in [freedesktop.org][1] and mention a few ways of solving it:

> - switching to a DVI-DBI cable from some other type
> - changing the connected monitor
> - downgrading from a 4.x kernel to a late 3.x series kernel

One interesting [article][2] at <http://01.org> suggested to add `i915.modeset=0` or `acpi=off` on your [Grub][3]. This actually fixed the black screen issue but two others emerged:

- CPU was rendering graphics which was pretty slow (`glxinfo | grep OpenGL` output string `llvmpipe`)
- Screen resolution wasn't the correct one. `arandr` listed only one resolution.

The following sections goes through the process of installing necessary video drivers and downgrading your kernel from 4.x to 3.x.


## Configure Xorg

After checking for errors and warnings on my `/var/log/Xorg.0.log`, had to install all this:

```
apt-get install mesa-utils
apt-get install xserver-xorg-video-intel
apt-get install libgl1-mesa
apt-get install libgl1-mesa-dri
apt-get install libdrm-intel1 libdrm2
```

Reboot and confirm with `glxinfo | grep OpenGL` that you're not rendering with your CPU.


## Downgrade to kernel 3.x

Still, screen resolution wasn't fixed. On [01.org - NUC5I3RYH - BLACK SCREEN - DEBIAN][2], [one comment][4] hinted that a previous kernel version actually works. The [freedesktop bug ticket][1] hinted the same. Tried to downgrade to jessies kernel and finally had my NUC displaying the correct resolution.

```
# Go to stable (currently jessie)
sed -i.original s/stretch/jessie/g /etc/apt/sources.list
apt-get update

# Find suited kernel package 
apt-cache search linux-image-3.*

# Find suited kernel version ("Candidate" field)
apt-cache policy linux-image-3.16.0-4-amd64 | grep Candidate

# Install kernel image & headers (kernel package=candidate version)
apt-get install linux-image-3.16.0-4-amd64=3.16.7-ckt25-1
apt-get install linux-headers-3.16.0-4-amd64=3.16.7-ckt25-1

# Fix kernel version (avoid update to 4.x.x)
apt-mark hold linux-headers-3.16.0-4-amd64
apt-mark hold linux-image-3.16.0-4-amd64

# Back to Testing
mv /etc/apt/sources.list.original /etc/apt/sources.list
```

Next step is to make grub to default to the newly installed kernel, so you don't need to switch manually.

```
# Find the newly installed kernel
cat /boot/grub/grub.cfg | grep menuentry | grep 'class os' | cut -d "'" -f2

# Update the /etc/default/grub with the new kernel (copy previous string)
NEW_GRUB_DEFAULT="Debian GNU/Linux, with Linux 3.16.0-4-amd64"
sed '/^GRUB_DEFAULT=/{h;s/=.*/='"$NEW_GRUB_DEFAULT"'/};${x;/^$/{s//GRUB_DEFAULT='"$NEW_GRUB_DEFAULT"'/;H};x}' -i.original /etc/default/grub

# Ensure you're happy with the changes
diff /etc/default/grub /etc/default/grub.original

# Update grub
# - You'll probably get an 'Warning: Please don't use old title'.
#   You can either ignore or follow the instructions to fix it.
update-grub2
```

If you don't have `update-grub2` or `update-grub`, you can simply create one:

```
cat <<'EOF' > /usr/sbin/update-grub2
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
EOF
chmod +x  /usr/sbin/update-grub2
```

### References

- Configure Xorg
  - <https://wiki.debian.org/Mesa>
- Downgrade kernel
  - <https://01.org/comment/2336#comment-2336>
  - <https://blog.okturtles.com/2014/06/how-to-downgrade-a-linux-kernel-on-debian/>
  - <http://askubuntu.com/questions/331538/what-is-the-right-way-to-downgrade-kernel>
  - <http://askubuntu.com/questions/418666/update-grub-command-not-found>

[1]: https://bugs.freedesktop.org/show_bug.cgi?id=92972
[2]: https://01.org/linuxgraphics/forum/graphics-installer-discussions/nuc5i3ryh-black-screen-debian
[3]: http://askubuntu.com/questions/160036/how-do-i-disable-acpi-when-booting
[4]: https://01.org/comment/2336#comment-2336