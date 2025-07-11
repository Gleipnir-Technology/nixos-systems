# nixos-systems

These are the system definitions for various systems being run by Gleipnir Technology.

## From Zero

Hat tip to [the negation](https://thenegation.com/posts/nixos-do-colmena/) for some ideas here.

Build a custom image for Digital Ocean:

```
> nix-build digitalocean/custom-image.nix
...
/nix/store/rm84j1a5bskhg2z8gz633m4apjyg848c-digital-ocean-image
> ls -lh result/
nixos-image-digital-ocean-25.05pre-git-x86_64-linux.qcow2.gz  nix-support/
```

In order to "upload" the image to Digital Ocean you'll need to make the image available via URL. We can use Gleipnir static storage as an example:

```
rsync result/nixos-image-digital-ocean-25.05pre-git-x86_64-linux.qcow2.gz static.gleipnir.technology:/tmp
```

Make sure the image is accessible via a public URL.
Then upload either through the web interface, or using [doctl](https://docs.digitalocean.com/reference/doctl/)

```
> doctl compute image create "Gleipnir NixOS 25.05" -v --image-description "NixOS 25.05 with ssh keys for eliribble baked in" --image-distribution nixos-25.05 --image-url "https://static.gleipnir.technology/nixos-image-digital-ocean-25.05pre-git-x86_64-linux.qcow2.gz" --region sfo3 --tag-names nixos
ID           Name                    Type      Distribution    Slug    Public    Min Disk    Created
192948683    Gleipnir NixOS 25.05    custom    Unknown OS              false     0           2025-07-10T20:22:43Z1G
```

Then start a droplet using that image:

```
> doctl compute droplet create "test2.nidus.cloud" --enable-ipv6 --image 192948683 --project-id ce2159e8-02f5-4169-8943-f34ccf812d23 --region sfo3 --size s-1vcpu-1gb --ssh-keys 48777034 --tag-name nixos --wait
Error: POST https://api.digitalocean.com/v2/droplets: 422 (request "116c778d-8e72-4099-a7c6-c3ad37557c4c") image is not compatible with ipv6
```

Oh. [Well that sucks](https://docs.digitalocean.com/products/custom-images/details/limits/). Digital Ocean can't do IPv6 on custom images.

## With cloud-init

I tried creating a cloud-init function based on NixOS-infect. You can see the content in `digitalocean/infect-nixos.yaml`. I added it to the startup command via `doctl compute droplet create ... --user-data-file digitalocean/infect-nixos.yaml`. This may have a way of working, but I don't get a log and it doesn't get infected, so something fundamental isn't working. I abandoned it.

## With nixos-anywhere.

First we start up a _really small_ s-1vcpu-1gb. Then we try to install nixos via nixos-anywhere. Notice the `--no-disko-deps` which is recommended for very low RAM systems:

```
$ nix run github:nix-community/nixos-anywhere -- --no-disko-deps --flake ./nixos-anywhere#digitalocean --target-host root@64.23.242.187
```

After an hour it was railed on the CPU at 100% and had been for an hour with no network data going anywhere. I gave up. Must be too small. Tried again with a larger system, `s-2vcpu-4gb`:

```
$ nix run github:nix-community/nixos-anywhere -- --flake ./nixos-anywhere/flake.nix#digitalocean --target-host root@128.199.4.31
```

This worked and I was then able to ssh in as root. Interestingly, it has no `/etc/nixos/*` files (but the directory does exist). Resulting disk images:

```
# fdisk -l
Disk /dev/vda: 80 GiB, 85899345920 bytes, 167772160 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: E0C9241B-89EA-4E2C-A0CD-04A3FDEFEDA2

Device       Start       End   Sectors  Size Type
/dev/vda1     2048      4095      2048    1M BIOS boot
/dev/vda2     4096   1028095   1024000  500M EFI System
/dev/vda3  1028096 167770111 166742016 79.5G Linux filesystem


Disk /dev/vdb: 482 KiB, 493568 bytes, 964 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/pool-root: 79.51 GiB, 85370863616 bytes, 166739968 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Next we'll try something at half that size

`s-1vcpu-2gb` works fine. We won't bother going smaller at this point.
