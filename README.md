# LazyChad 🚀

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but are far too lazy to actually configure it.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated installation attempts and a 120s safety timeout for repository additions.
- **🛡️ Cross-Distro Intelligence**: Automatically detects **Kali Linux** and other "Frankendebian" environments to safely install Neovim via AppImage instead of potentially breaking PPAs.
- **🔄 Smart Synchronization**: Automatically detects system updates and prompts you to refresh your local configuration with a safe, timestamped backup.
- **💎 Luminous Aesthetics**: Custom "Intelligence Report" dashboard with real-time toolchain status and the beautiful Rose Pine theme.
- **🖼️ Neovide Optimized**: Pre-configured for the **Neovide** GUI with smooth 120Hz animations, "pixiedust" cursor effects, and perfect typography.
- **🔡 Typography Ready**: Out-of-the-box support for **JetBrainsMono Nerd Font** for perfect icons and coding clarity.
- **🚀 Future-Proof**: Native support for Neovim 0.11+ and the new `vim.lsp.config` API.

---

## 📥 Installation

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
sudo apt install ./lazychad_1.3.8_all.deb
```
*Note: Kali Linux users will automatically get the AppImage version during `lazychad-deps` to ensure system stability.*

### Option 3: Fedora / RHEL (.rpm)
Download the latest `.rpm` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo dnf install ./lazychad-1.3.8-1.noarch.rpm
```
*Note: Fedora users get the latest Neovim Nightly via the `agriffis` COPR repository.*

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
Run the built-in dependency script to set up Node, Python, and Rust providers:
```bash
lazychad-deps
```

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
*On Kali Linux or AppImage installations, the script will ask if you want to refresh the latest Nightly build.*

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

## 🗑️ Uninstallation

**If installed via AUR:**
```bash
sudo pacman -R lazychad
```

**If installed manually:**
```bash
rm -rf ~/.config/LazyChad ~/.local/share/LazyChad ~/.local/state/LazyChad ~/.cache/LazyChad
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
