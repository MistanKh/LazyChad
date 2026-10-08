# LazyChad 🚀

> 📄 Case study & write-up: **[mistan.dev/projects/lazychad](https://mistan.dev/projects/lazychad/)**

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but are far too lazy to actually configure it.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated failed tool-install attempts during toolchain setup.
- **🛡️ Cross-Distro Intelligence**: Bundles `lazychad-nvim`, which installs the latest stable Neovim (LazyChad needs 0.12+) from the official GitHub release tarball, checksum-verified, on any distro (x86_64 / arm64) — no PPAs, COPRs, or AppImages to break, and no fight with an outdated repo package.
- **🔄 Smart Synchronization**: Automatically detects system updates and prompts you to refresh your local configuration with a safe, timestamped backup.
- **💎 Luminous Aesthetics**: Custom "Intelligence Report" dashboard with real-time toolchain status and the beautiful Rose Pine theme.
- **🖼️ Neovide Optimized**: Pre-configured for the **Neovide** GUI with smooth 120Hz animations, "pixiedust" cursor effects, and perfect typography.
- **🔡 Typography Ready**: Out-of-the-box support for **JetBrainsMono Nerd Font** for perfect icons and coding clarity.
- **🚀 Future-Proof**: Targets Neovim 0.12+ (as required by `nvim-treesitter`) and the new `vim.lsp.config` API.

---

## 📥 Installation

### ⚡ Quick install (recommended)
One command for Arch, Debian/Ubuntu/Kali and Fedora (plus derivatives; on
RHEL/Rocky/Alma/Oracle, [enable EPEL](#option-3-fedora--rhel-rpm) first):
```bash
curl -fsSL https://raw.githubusercontent.com/MistanKh/LazyChad/main/install.sh | bash
```
It installs the latest release with your package manager (AUR, `.deb` or
`.rpm`, checksum-verified), then runs `lazychad-deps` to install Neovim 0.12+,
the language tools and every plugin. When it finishes, `lchad` opens straight
into a ready editor. Run it as your normal user; it asks for `sudo` when needed.

Options go after `bash -s --`, e.g. add the Neovide GUI:
```bash
curl -fsSL https://raw.githubusercontent.com/MistanKh/LazyChad/main/install.sh | bash -s -- --gui
```
(`--version X.Y.Z` pins a release (not on Arch, where the AUR always has the
latest), `--no-deps` installs only the package, and `--gui`, `--nightly`,
`--skip-nvim` and `--no-bootstrap` are passed to `lazychad-deps`; `--help` lists
them all.)

> [!WARNING]
> **Upgrading a `.deb`/`.rpm` from v1.0.9 or earlier?** Those versions deleted
> every user's LazyChad config during upgrades. Newer packages move your data
> aside while the old package's removal script runs and put it back afterwards,
> but back up `~/.config/LazyChad` first to be safe.

### Installing by hand
> [!IMPORTANT]
> **With any of the options below, run `lazychad-deps` afterward.** Installing
> the package alone does **not** give you a recent Neovim — `lazychad-deps`
> installs the latest stable Neovim (0.12+, required by `nvim-treesitter`) via the
> bundled `lazychad-nvim` script, the Node and Python providers, and all
> plugins. Without it you'll be left on your distro's (often outdated) Neovim.

### Option 1: Arch Linux (AUR)
If you are on Arch Linux or CachyOS, you can install LazyChad directly from the AUR. 

**Using yay:**
```bash
yay -S lazychad
```

**Using paru:**
```bash
paru -S lazychad
```

Then run `lazychad-deps`.

### Option 2: Debian / Ubuntu / Kali (.deb)
Download the latest `.deb` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo apt install ./lazychad_1.0.9-1_all.deb
lazychad-deps   # required: installs Neovim 0.12+, tools and plugins
```
*Note: `neovim` is a **recommended** (not required) dependency, so apt may pull in your distro's older Neovim — that's harmless. `lazychad-deps` then installs the latest stable Neovim to `/usr/local`, which shadows it via `PATH`. Keeping `neovim` a recommend (not a hard depend) is also what stops a system `neovim` removal from cascade-removing LazyChad.*

### Option 3: Fedora / RHEL (.rpm)
On RHEL, Rocky, Alma and Oracle Linux, LazyChad's dependencies (ripgrep,
fd-find, pynvim, ...) come from EPEL, so enable it first:
```bash
sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb   # Rocky / Alma
# RHEL: subscription-manager repos --enable codeready-builder-for-rhel-$(rpm -E %rhel)-$(arch)-rpms
#       then dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
# Oracle Linux: dnf install oracle-epel-release-el$(rpm -E %rhel)
```

Download the latest `.rpm` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo dnf install ./lazychad-1.0.9-1.noarch.rpm
lazychad-deps   # required: installs Neovim 0.12+, tools and plugins
```
*Note: `lazychad-deps` installs the latest stable Neovim via the bundled `lazychad-nvim` script (official release tarball) — no COPR repository needed.*

### Option 4: Manual Installation
Works on any Linux. On distros outside the Arch, Debian and Fedora families
(openSUSE, Alpine, Void, ...), `lazychad-deps` can't install system packages
for you: first install `git curl tar unzip make gcc ripgrep fd nodejs npm
python3` plus your distro's pynvim and `xclip` or `wl-clipboard`, then follow
these steps.

#### 1. Clone LazyChad
Clone the repository into your config directory under the name `LazyChad` to keep it isolated.
```bash
git clone https://github.com/MistanKh/LazyChad ~/.config/LazyChad
```

#### 2. Add to PATH
Add the `bin` directory to your shell's PATH to enable the `lchad` command.

**For Bash/Zsh:**
```bash
echo 'export PATH="$HOME/.config/LazyChad/bin:$PATH"' >> ~/.bashrc # or ~/.zshrc
source ~/.bashrc # or ~/.zshrc
```

**For Fish:**
```fish
fish_add_path ~/.config/LazyChad/bin
```

#### 3. Install Dependencies
Run the built-in dependency script to install Neovim (latest stable, 0.12+), the
language tools and all plugins:
```bash
lazychad-deps
```
`lazychad-deps` is **best-effort**: it auto-detects your distro family (including
derivatives like Mint, Pop!_OS, EndeavourOS, Rocky), keeps going if one optional
step fails, prints a summary of anything that needs attention at the end, and
auto-links `fdfind` → `fd` on Debian/Fedora. Just re-run it after fixing any
reported issue. Each run is logged to `~/.local/state/LazyChad/lazychad-deps.log`.

It only installs what LazyChad needs:
- System packages (including your distro's `pynvim` for the Python provider).
- JetBrainsMono Nerd Font for icons (on Debian/Fedora it goes into
  `~/.local/share/fonts`; on Arch it's the `ttf-jetbrains-mono-nerd` package).
  Pick it in your terminal's font settings.
- The Node provider and `tree-sitter` CLI in a private npm prefix under
  `~/.local/share/LazyChad` (no `sudo npm -g`).
- Plugins, base Mason tools and treesitter parsers, so the first launch is instant.

| Flag | What it does |
| --- | --- |
| `--gui` | Also install the Neovide GUI (Rust is only installed if Neovide must be built) |
| `--nightly` | Install Neovim nightly instead of the latest stable release |
| `--skip-nvim` | Leave Neovim alone |
| `--no-bootstrap` | Skip pre-installing plugins (`lchad` does it on first launch) |

---

## 🔄 Updating LazyChad

### Step 1: Update the Package
*   **Arch Linux**: `paru -Syu` or `yay -Syu`
*   **Fedora/RHEL**: Download and install the new `.rpm` (`sudo dnf install ./lazychad-<version>-1.noarch.rpm`).
*   **Debian/Ubuntu/Kali**: Download and install the new `.deb`.
*   **Manual**: `cd ~/.config/LazyChad && git pull`

### Step 2: Synchronize Configuration
Run `lchad`. If a system-wide update is detected, LazyChad will automatically prompt:
`🔔 System update detected (v1.3.7 -> v1.3.8)!`

Press `y` to sync. Your old configuration will be safely backed up to a timestamped folder in `~/.config/`.
Package upgrades and removals never delete your config; only `apt purge` or `lazychad-uninstall` does.

### Step 3: Refresh Toolchain
Run the dependency script to ensure your Neovim, Node, and Python providers are up to date:
```bash
lazychad-deps
```

---

## 🛠️ Managing Neovim

LazyChad bundles `lazychad-nvim`, which installs Neovim from the official
GitHub release tarball into `/usr/local` (so it shadows any distro `neovim`
package via `PATH`). It installs the latest **stable** release, since LazyChad
needs 0.12+ (required by `nvim-treesitter`); if stable were ever older than
that, it falls back to nightly. It detects your CPU (x86_64 / arm64) and, if the download is
unavailable, falls back to your system package manager — picking it by which
binary exists (`pacman`/`dnf`/`zypper`/`apt-get`/`apk`/`xbps`), so derivatives
(Mint, EndeavourOS, Rocky, openSUSE, …) work too. Either way it **verifies the
result is 0.12+** and refuses to report success on anything older. Tarball
downloads are checked against Neovim's published SHA-256 checksums.

```bash
lazychad-nvim              # install/update the latest stable Neovim (default)
lazychad-nvim --nightly    # track nightly builds instead
lazychad-nvim --uninstall  # remove the /usr/local Neovim install
```

`lazychad-deps` runs this automatically as its Neovim step (`lazychad-deps --nightly`
for nightly). Switching back from nightly to stable cleans the old runtime files first.

## 🗑️ Uninstalling

The recommended way is the bundled uninstaller, which is install-method aware:

```bash
lazychad-uninstall       # confirm + optional config backup, then remove
lazychad-uninstall --yes # skip prompts (scripted use)
```

This removes the LazyChad package, the bundled Neovim, and every user's
LazyChad directories (after offering a backup of yours). It detects whether
LazyChad was installed via `apt` (it purges), `pacman`, `dnf`/`zypper` (rpm) or
manually and removes it the matching way. If the package manager fails (for
example because it is locked), it stops before touching Neovim or anyone's data.
Shared tools (Node, Rust, Neovide, fonts) are **not** removed.

<details>
<summary>Manual removal (if you didn't install the <code>lazychad-uninstall</code> script)</summary>

```bash
# Bundled Neovim under /usr/local, if installed via lazychad-nvim (do this first,
# while the lazychad-nvim script is still installed):
lazychad-nvim --uninstall

# Package installs:
sudo pacman -R lazychad        # Arch / AUR
sudo apt purge lazychad        # Debian / Ubuntu / Kali (purge also removes user data)
sudo dnf remove lazychad       # Fedora / RHEL

# Config/data (removing the package keeps these):
rm -rf ~/.config/LazyChad ~/.local/share/LazyChad ~/.local/state/LazyChad ~/.cache/LazyChad
```
</details>

---

## 🚀 Getting Started

Once installed, simply type:
```bash
lchad
```

Plugins, base Mason tools and parsers are already installed by `lazychad-deps`
(if you skipped it, the first `lchad` launch installs them before opening).

1.  **Open a File**: Open any code file (e.g., `lchad main.py`).
2.  **Pick Your Tools**: LazyChad will automatically prompt you to choose an LSP, Formatter, and Linter.
    Change them later with `:LspPick`, `:FormatPick` and `:LintPick`.

### Handy commands
```bash
lchad --doctor      # check Neovim, tools, providers, fonts, config and plugins
lchad --setup       # same as lazychad-deps
lchad --bootstrap   # (re)install plugins, Mason tools and parsers headlessly
lchad --lchad-help  # LazyChad's own options (--help goes to Neovim)
```

---

## 🛌 The Lazy Origin Story

This project was born out of a profound, almost spiritual commitment to doing as little as possible. 

The "author" of this config didn't actually write most of it. In fact, even this sentence was probably generated while they were looking for a snack. LazyChad is the ultimate expression of **Human-AI Synergy**, where the human provides the lack of motivation and the AI provides the logic.

### 🤖 The Real Brains:
- **Google Gemini**: The primary architect, debugger, and the one who actually figured out how to fix the `ts_ls` crash.
- **OpenAI Codex**: The spiritual predecessor and legacy partner that kept the wheels turning.

---

## 💖 Credits

LazyChad is built with passion on the **NvChad** platform. Special thanks to the NvChad team, Google Gemini, and the community for the incredible foundation.

---

**"I will always choose a lazy person to do a difficult job because a lazy person will find an easy way to do it." — Not me, but I agree.** ▀
