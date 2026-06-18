# LazyChad 🚀

> 📄 Case study & write-up: **[mistan.dev/projects/lazychad](https://mistan.dev/projects/lazychad/)**

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but are far too lazy to actually configure it.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated failed tool-install attempts during toolchain setup.
- **🛡️ Cross-Distro Intelligence**: Bundles `lazychad-nvim`, which installs Neovim (nightly by default, since LazyChad needs 0.12+) from the official GitHub release tarball on any distro (x86_64 / arm64) — no PPAs, COPRs, or AppImages to break, and no fight with an outdated repo package.
- **🔄 Smart Synchronization**: Automatically detects system updates and prompts you to refresh your local configuration with a safe, timestamped backup.
- **💎 Luminous Aesthetics**: Custom "Intelligence Report" dashboard with real-time toolchain status and the beautiful Rose Pine theme.
- **🖼️ Neovide Optimized**: Pre-configured for the **Neovide** GUI with smooth 120Hz animations, "pixiedust" cursor effects, and perfect typography.
- **🔡 Typography Ready**: Out-of-the-box support for **JetBrainsMono Nerd Font** for perfect icons and coding clarity.
- **🚀 Future-Proof**: Targets Neovim 0.12+ (as required by `nvim-treesitter`, currently only on the nightly channel) and the new `vim.lsp.config` API.

---

## 📥 Installation

> [!IMPORTANT]
> **Whatever method you use, you must run `lazychad-deps` afterward.** Installing
> the package alone does **not** give you a recent Neovim — `lazychad-deps`
> installs Neovim **nightly** (0.12+, required by `nvim-treesitter`; the current
> stable line is still 0.11) via the bundled `lazychad-nvim` script, plus the
> Node/Python/Rust providers. Without it you'll be left on your distro's (often
> outdated) Neovim.

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

### Option 2: Debian / Ubuntu / Kali (.deb)
Download the latest `.deb` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo apt install ./lazychad_1.0.9-1_all.deb
lazychad-deps   # required: installs the latest Neovim + providers
```
*Note: `neovim` is a **recommended** (not required) dependency, so apt may pull in your distro's older Neovim — that's harmless. `lazychad-deps` then installs Neovim nightly to `/usr/local`, which shadows it via `PATH`. Keeping `neovim` a recommend (not a hard depend) is also what stops a system `neovim` removal from cascade-removing LazyChad.*

### Option 3: Fedora / RHEL (.rpm)
Download the latest `.rpm` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo dnf install ./lazychad-1.0.9-1.noarch.rpm
lazychad-deps   # required: installs the latest Neovim + providers
```
*Note: `lazychad-deps` installs Neovim nightly via the bundled `lazychad-nvim` script (official release tarball) — no COPR repository needed.*

### Option 4: Manual Installation (All Linux/macOS)
If you prefer to install manually, follow these steps:

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
Run the built-in dependency script to install Neovim (nightly, 0.12+) and set up the Node, Python, and Rust providers:
```bash
lazychad-deps
```
`lazychad-deps` is **best-effort**: it auto-detects your distro family (including
derivatives like Mint, Pop!_OS, EndeavourOS, Rocky), keeps going if one optional
step fails, prints a summary of anything that needs attention at the end, and
auto-links `fdfind` → `fd` on Debian/Fedora. Just re-run it after fixing any
reported issue.

---

## 🔄 Updating LazyChad

### Step 1: Update the Package
*   **Arch Linux**: `paru -Syu` or `yay -Syu`
*   **Fedora**: `sudo dnf update lazychad`
*   **Debian/Ubuntu/Kali**: Download and install the new `.deb`.
*   **Manual**: `cd ~/.config/LazyChad && git pull`

### Step 2: Synchronize Configuration
Run `lchad`. If a system-wide update is detected, LazyChad will automatically prompt:
`🔔 System update detected (v1.3.7 -> v1.3.8)!`

Press `y` to sync. Your old configuration will be safely backed up to a timestamped folder in `~/.config/`.

### Step 3: Refresh Toolchain
Run the dependency script to ensure your Neovim, Node, and Python providers are up to date:
```bash
lazychad-deps
```

---

## 🛠️ Managing Neovim

LazyChad bundles `lazychad-nvim`, which installs Neovim from the official
GitHub release tarball into `/usr/local` (so it shadows any distro `neovim`
package via `PATH`). It defaults to the **nightly** channel because LazyChad
needs 0.12+ (required by `nvim-treesitter`) and the current stable line is
still 0.11. It detects your CPU (x86_64 / arm64) and, if the download is
unavailable, falls back to your system package manager — picking it by which
binary exists (`pacman`/`dnf`/`zypper`/`apt-get`/`apk`/`xbps`), so derivatives
(Mint, EndeavourOS, Rocky, openSUSE, …) work too. Either way it **verifies the
result is 0.12+** and refuses to report success on anything older.

```bash
lazychad-nvim              # install/update Neovim nightly (default — what LazyChad needs)
lazychad-nvim --stable     # install the latest stable release instead (0.11.x)
lazychad-nvim --uninstall  # remove the /usr/local Neovim install
```

`lazychad-deps` runs this automatically as its Neovim step (nightly).

## 🗑️ Uninstalling

The recommended way is the bundled uninstaller, which is install-method aware:

```bash
lazychad-uninstall       # confirm + optional config backup, then remove
lazychad-uninstall --yes # skip prompts (scripted use)
```

This removes the bundled Neovim, the LazyChad binaries and files, and the
per-user LazyChad directories. It detects whether LazyChad was installed via
`apt`/`pacman` or manually and removes it the matching way. Shared tools
(Node, Rust, Neovide, fonts) are **not** removed.

<details>
<summary>Manual removal (if you didn't install the <code>lazychad-uninstall</code> script)</summary>

```bash
# Package installs:
sudo pacman -R lazychad        # Arch / AUR
sudo apt remove lazychad       # Debian / Ubuntu / Kali
sudo dnf remove lazychad       # Fedora / RHEL

# Config/data (all install types):
rm -rf ~/.config/LazyChad ~/.local/share/LazyChad ~/.local/state/LazyChad ~/.cache/LazyChad

# Bundled Neovim under /usr/local, if installed via lazychad-nvim:
lazychad-nvim --uninstall
```
</details>

---

## 🚀 Getting Started

Once installed, simply type:
```bash
lchad
```

### Post-Installation Steps:
1.  **Wait for Plugins**: Let `lazy.nvim` finish installing all the core plugins on the first boot.
2.  **Bootstrap Essentials**: Run `:MasonInstallAll` to install the base language server and formatter for your Neovim config.
3.  **Open a File**: Open any code file (e.g., `main.py`).
4.  **Pick Your Tools**: LazyChad will automatically prompt you to choose an LSP, Formatter, and Linter.

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
