# LazyChad 🚀

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but are far too lazy to actually configure it.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated installation attempts if a tool fails.
- **💎 Luminous Aesthetics**: Custom "Intelligence Report" dashboard with real-time toolchain status and the beautiful Rose Pine theme.
- **🖼️ Neovide Optimized**: Pre-configured for the **Neovide** GUI with smooth 120Hz animations, "pixiedust" cursor effects, and perfect typography.
- **🔡 Typography Ready**: Out-of-the-box support for **JetBrainsMono Nerd Font** for perfect icons and coding clarity.
- **🚀 Future-Proof**: Native support for Neovim 0.11+ and the new `vim.lsp.config` API.

---

## 📥 Installation

### Option 1: Arch Linux (AUR)
If you are on Arch Linux, you can install LazyChad directly from the AUR. This is the recommended method as it handles all dependencies and provides a system-wide `lchad` command.

**Using yay:**
```bash
yay -S lazychad
```

**Using paru:**
```bash
paru -S lazychad
```

### Option 2: Debian / Ubuntu (.deb)
Download the latest `.deb` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo apt install ./lazychad_1.0.1_all.deb
```

### Option 3: Fedora / RHEL (.rpm)
Download the latest `.rpm` package from our [Releases Page](https://github.com/MistanKh/LazyChad/releases) and install it:
```bash
sudo dnf install ./lazychad-1.0.1-10.noarch.rpm
```

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
