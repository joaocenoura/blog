---
layout: post
title:  "Simple CDD - No kernel modules were found"
date:   2016-05-18 19:01:00
categories: [debian, simple-cdd]
---

After producing an iso with simple-cdd and booting it, debian installer throws this error:

```
No kernel modules were found. This probably is due to a mismatch between the
kernel used by this version of the installer and the kernel version available in
the archive.

If you're installing from a mirror, you can work around this problem by choosing
to install a different version of Debian. The install will probably fail to work
if you continue without kernel modules.

Continue to install without loading kernel modules?
```

One solution from the documentation and the [mailing list](https://lists.alioth.debian.org/pipermail/simple-cdd-devel/2009-September/000006.html) is:

```
$ echo 'export DI_WWW_HOME=default' >> profiles/default.conf
```

This will force simple-cdd to call debian-cd to the latest daily build: <https://d-i.debian.org/daily-images/amd64/daily/>

However that may not solve it or you may already had `DI_WWW_HOME=default` properly configured and suddenly you started to get this error. The latter was my case - I was running simple-cdd for a few days in a row and this error appeared and persisted during a few more days.

So back to the error: there was a mismatch between kernel version and installer. Let's check versions we have:

```
# check installer version
$ file $simple_cdd_dir/tmp/cd-build/stretch/CD1/install.amd/vmlinuz

tmp/cd-build/stretch/CD1/install.amd/vmlinuz: Linux kernel x86 boot executable
bzImage, version 4.5.0-2-amd64 (debian-kernel@lists.debian.org) #1 SMP Debian 4.,
RO-rootFS, swap_dev 0x3, Normal VGA

# check kernel version
$ find $simple_cdd_dir/tmp/cd-build/ -name "linux-image-*-amd64*"
tmp/cd-build/stretch/CD1/pool/main/l/linux/linux-image-4.5.0-1-amd64_4.5.1-1_amd64.deb
```

Notice that installer version was ahead (`4.5.0-2-amd64`) than kernel version (`4.5.0-1-amd64`). The solution was to find out the installer version 4.5.0-1-amd64 and update the `profiles/default.conf`:

```
export DI_WWW_HOME=https://d-i.debian.org/daily-images/amd64/20160430-00:16

```

Now here we're explicitly pointing the installer to the 2016-04-30 build, which was the day before I got the error. Re-run simple-cdd and versions did match:

```
# installer version is now in 4.5.0-1
$ file $simple_cdd_dir/tmp/cd-build/stretch/CD1/install.amd/vmlinuz
tmp/cd-build/stretch/CD1/install.amd/vmlinuz: Linux kernel x86 boot executable
bzImage, version 4.5.0-1-amd64 (debian-kernel@lists.debian.org) #1 SMP Debian 4.,
RO-rootFS, swap_dev 0x3, Normal VGA

# kernel version is the same - 4.5.0-1
$ find $simple_cdd_dir/tmp/cd-build/ -name "linux-image-*-amd64*"
tmp/cd-build/stretch/CD1/pool/main/l/linux/linux-image-4.5.0-1-amd64_4.5.1-1_amd64.deb
```

Booting the produced iso and the `No kernel modules were found` was gone.

Note that the kernel version should be updated in the repositories to 4.5.0-2 in the meantime. Then the kernel version will be ahead of installers and probably will produce the error again. Switching back to `DI_WWW_HOME=default` should put both versions aligned for awhile.
