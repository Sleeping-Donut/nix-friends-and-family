# Nix Friend and Family Semi-Managed System

Nix flakes to make an easy to update robust system for friends and family.

## Deployment & Setup Guide

### Step 0: Disk Setup (Only for Fresh CLI Installs)

> [!NOTE]
> If you used the NixOS Graphical Installer (Calamares) first, skip to **Step 1**.

Recommended Btrfs layout:
- **`@root`** (`/`): OS root
- **`@home`** (`/home`): User data
- **`@nix`** (`/nix`): Nix store (separated so Btrfs root snapshots don't waste space on package caches)
- **`@log`** (`/var/log`): System logs (separated so logs persist if you ever rollback `@root`)

```sh
# 1. Partition drive (e.g. using cfdisk, parted, gdisk, or disko)
# p1: EFI Boot ~1GB, p2: Swap ~4-16GB, p3: Btrfs Root rest of disk
sudo cfdisk /dev/nvme0n1

# 2. Format partitions
sudo mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
sudo mkswap -L SWAP /dev/nvme0n1p2
sudo swapon /dev/nvme0n1p2
sudo mkfs.btrfs -f -L NIXOS /dev/nvme0n1p3

# 3. Create Btrfs subvolumes
sudo mount /dev/disk/by-label/NIXOS /mnt
sudo btrfs subvolume create /mnt/@root
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@log
sudo umount /mnt

# 4. Mount subvolumes with zstd compression
sudo mount -o subvol=@root,compress=zstd,noatime /dev/disk/by-label/NIXOS /mnt
sudo mkdir -p /mnt/{boot,home,nix,var/log}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/disk/by-label/NIXOS /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/disk/by-label/NIXOS /mnt/nix
sudo mount -o subvol=@log,compress=zstd,noatime /dev/disk/by-label/NIXOS /mnt/var/log
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

### Step 1: Initialise template

If doing a fresh CLI install, target `/mnt/etc/nixos`. If modifying a running system, use `/etc/nixos`.

```sh
# Target directory (use /mnt/etc/nixos for fresh live USB install, or /etc/nixos for existing system)
cd /mnt/etc/nixos # or cd /etc/nixos

sudo nix --extra-experimental-features 'nix-command flakes' flake init -t github:Sleeping-Donut/nix-friends-and-family
```

### Step 2: Generate Hardware Configuration

Generate the hardware file for this specific device:

```sh
# If running from Live USB targeting /mnt:
sudo nixos-generate-config --root /mnt
sudo rm /mnt/etc/nixos/configuration.nix

# If running on an already installed system:
# sudo nixos-generate-config --root /
```

### Step 3: Configure `flake.nix`

Open `flake.nix` in a text editor:

```sh
sudo vi flake.nix
```

1. `PC_NAME_HERE`: Match target system hostname in both `nixosConfigurations` and `networking.hostName`.
2. `USERNAME_HERE`: Set target username.
3. `desktop`: Choose `"gnome"`, `"kde"`, or `"none"`.
4. `bootloader`: Choose `"systemd-boot"`, `"grub"`, or `"limine"`.
5. `nixos-hardware`: (Optional) Uncomment hardware module if using a supported laptop.

> [!IMPORTANT]
> Initialize Git before installing (Flakes will fail if files are untracked):
> ```sh
> sudo git init
> sudo git add .
> ```

### Step 4: Install or Rebuild

- Option A - Fresh Live USB Install:
    ```sh
    sudo nixos-install --flake .#default
    sudo nixos-enter --command "passwd USERNAME_HERE" # Set user password
    sudo reboot
    ```
- Option B - Existing Running System:
    ```sh
    sudo nixos-rebuild switch --flake .#default
    ```

### Step 5: Post-Install Home Manager Setup

Run this AFTER booting into the newly installed system as the user (or via `nixos-enter`):

