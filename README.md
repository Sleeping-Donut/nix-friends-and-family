# Nix Friend and Family Semi-Managed System

Nix flakes to make an easy to update robust system for friends and family.

## Default Configuration

### System Maintenance & Upgrades
- **Automatic Minor Updates:** Installed in the background and activated on the next boot.
- **Controlled Major Updates:** Triggered only via upstream source to prevent unexpected breaking changes on managed systems.
- **Automatic Garbage Collection:** Periodically cleans the Nix store to conserve disk space.
- **Nix Flakes:** `flakes` and `nix-command` experimental features enabled by default.

### Hardware & Desktop Experience
- **Desktop Environments:** Simplified toggles for **KDE Plasma** or **GNOME**.
- **Bootloader & Splash:** Configurable support for `systemd-boot`, `grub`, or `limine` alongside a Plymouth boot screen.
- **Connectivity & Hardware:** NetworkManager, Bluetooth, CUPS printing, and FWUPD firmware updating enabled out of the box.
- **Locale:** Defaults to `en_GB`

### Application & User Management
- **Home Manager:** Pre-integrated for user-level configuration management.
- **Flatpak Integration:** Flathub enabled out of the box.
  - **Weekly Auto-Updates:** Flatpaks automatically update on a weekly schedule.
  - **Store Front:** Bazaar installed as the default GUI store.
  - **Permission Management:** Environment-aware tools integrated automatically (Flatseal for GNOME, KDE Flatpak KCM for KDE).
### Security & Parental Controls
- **Admin-Gated Flatpaks:** Optional toggle to require `wheel`/admin privileges for Flatpak management.
- **Child-Safer Networking:** Local `dnsmasq` DNS filtering with Cloudflare Family (1.1.1.3) upstream, forced YouTube Restricted Mode, and wildcard domain blocking (e.g., TikTok).

## Deployment & Setup Guide

### Step 0: Disk Setup (Only for Fresh CLI Installs)

> [!NOTE]
> If you used the NixOS Graphical Installer (Calamares) first, skip to **Step 1**.

<details>
<summary><strong>
Manual Btrfs partitioning and mounting steps
</strong></summary>

| Partition@Subvolume | Mount Point | Recommended Size | Purpose |
| :--- | :--- | :--- | :--- |
| **`p1`**      | `/boot`    |~1-2GB        | EFI boot |
| **`p2`**      | swap       | ~4-16GB      | Swap |
| **`p3`**      | -          | Rest of disk | Btrfs root |
| **`p3@root`** | `/`        | -            | OS root |
| **`p3@home`** | `/home`    | -            | User data |
| **`p3@nix`**  | `/nix`     | -            | Nix store - split for separate snapshots |
| **`p3@log`**  | `/var/log` | -            | System logs - split for separate snapshots |

```sh
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git nixpkgs#neovim nixpkgs#parted nixpkgs#btrfs-progs nixpkgs#dosfstools

DISK='/dev/nvme0n1'
PARTITION="${DISK}p" # for mmcblk or nvme put p at end, for sda type drives omit p

# 1. Partition drive (e.g. using cfdisk, parted, gdisk, or disko)
sudo cfdisk "$DISK"

# 2. Format partitions
sudo mkfs.fat -F32 -n BOOT "${PARTITION}1"
sudo mkswap -L SWAP "${PARTITION}2"
sudo swapon "${PARTITION}2"
sudo mkfs.btrfs -f -L NIXOS "${PARTITION}3"

# 3. Create Btrfs subvolumes
sudo mount "${PARTITION}3" /mnt
sudo btrfs subvolume create /mnt/@root
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@log
sudo umount /mnt

# 4. Mount subvolumes with zstd compression
sudo mount -o subvol=@root,compress=zstd,noatime "${PARTITION}3" /mnt
sudo mkdir -p /mnt/{boot,home,nix,var/log}
sudo mount -o subvol=@home,compress=zstd,noatime "${PARTITION}3" /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime "${PARTITION}3" /mnt/nix
sudo mount -o subvol=@log,compress=zstd,noatime "${PARTITION}3" /mnt/var/log
sudo mount "${PARTITION}1" /mnt/boot
```

</details>

### Step 1: Initialise template

If doing a fresh CLI install, target `/mnt/etc/nixos`. If modifying a running system, use `/etc/nixos`.

```sh
# Target directory (use /mnt/etc/nixos for fresh live USB install, or /etc/nixos for existing system)
mkdir -p /mnt/etc/nixos
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
3. Change `system.autoUpgrade.flake` to match the location of your flake.
3. `desktop`: Choose `"gnome"`, `"kde"`, or `"none"`.
4. `bootloader`: Choose `"systemd-boot"`, `"grub"`, or `"limine"`.
5. `nixos-hardware`: (Optional) Uncomment hardware module if using a supported laptop.

> [!IMPORTANT]
> Initialize Git before installing (Flakes will fail if files are untracked):
> ```sh
> # Needs git config user.name and user.email set
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
  sudo nixos-rebuild boot --flake .#default
  sudo reboot
  ```

### Step 5: Post-Install Home Manager Setup

Run this AFTER booting into the newly installed system as the user (or via `nixos-enter`):

Symlink the home.nix file to the user's home dir. Do this for each user defined in the config.
This allows each user to have their own packages and environment controlled by them.

```sh
# /etc/nixos/USERNAME_HERE.nix -> /home/USERNAME_HERE/home.nix
chmod ug=rw,o= /etc/nixos/home.nix
chown :USERNAME_HERE /etc/nixos/home.nix
ln -s /etc/nixos/home.nix /home/USERNAME_HERE/home.nix
```

#### Restricting Users

Some users might need to be restricted if its a child account or the like.
To apply restrictions for child or restricted user accounts, configure the `restrictions` block inside the `flake.nix`:

- **Require admin (`wheel`) for Flatpak installs:** Prevent non-admin users changing flatpak stuff.
    ```nix
    restrictions.flatpakNeedsWheel = true;
    ```
- **Child-Safer Network & DNS Filtering:** Enforces Cloudflare Family DNS (1.1.1.3), redirects YouTube to Google's Restricted Mode VIP, and blocks TikTok domains via a local dnsmasq instance.
    ```nix
    nixFriendsAndFamily.restrictions.childSaferNetwork = {
      enable = true;
      blockTikTok = true;
      youtubeRestrictedMode = "strict"; # Options: "strict", "moderate", "block", "none"
      childFriendlyDns = true;
    };
    ```

## Extra things to note

These configs should work for raspberry pi as well, however there will probably need to be other stuff options set in your flake.
See the [nixos raspberry pi docs](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi) page for details.

