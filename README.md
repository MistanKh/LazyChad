# LazyChad 🚀

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but are far too lazy to actually configure it.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated installation attempts if a tool fails.
- **💎 Luminous Aesthetics**: Custom "Intelligence Report" dashboard with real-time toolchain status and the beautiful Rose Pine theme.
- **🚀 Future-Proof**: Native support for Neovim 0.11+ and the new `vim.lsp.config` API.

---

## 📥 Installation

### 1. Clone LazyChad
Clone the repository into your config directory under the name `LazyChad` to keep it isolated from your main Neovim configuration.
```bash
git clone https://github.com/MistanKh/LazyChad ~/.config/LazyChad
```

### 2. Add the wrapper to your PATH
To run LazyChad conveniently, add its `bin` directory to your shell's PATH.

**For Bash/Zsh:**
```bash
echo 'export PATH="$HOME/.config/LazyChad/bin:$PATH"' >> ~/.bashrc # or ~/.zshrc
source ~/.bashrc # or ~/.zshrc
```

**For Fish:**
```fish
fish_add_path ~/.config/LazyChad/bin
```

### 3. Start LazyChad
Now you can launch it using the simple `lazychad` command:
```bash
lazychad
```

---

## 🛠️ Post-Installation

Once you've launched LazyChad for the first time, follow these steps:

1.  **Wait for Plugins**: Let `lazy.nvim` finish installing all the core plugins.
2.  **Bootstrap Essentials**: Run `:MasonInstallAll` to install the base language server and formatter for your Neovim config itself.
3.  **Open a File**: Open any code file (e.g., `test.js` or `main.py`).
4.  **Pick Your Tools**: LazyChad will automatically prompt you to choose an LSP, Formatter, and Linter. Make your choice once, and you're set for life.

---

## 🗑️ Uninstallation

To remove LazyChad and clean up its data, run:

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

LazyChad is built with passion on the **NvChad** platform. We owe a huge debt of gratitude to the NvChad team for providing the incredible aesthetic foundation and plugin architecture that made this project possible for a lazy person like me.

Special thanks to:
- [NvChad](https://github.com/NvChad/NvChad)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Mason.nvim](https://github.com/williamboman/mason.nvim)

---

**"I will always choose a lazy person to do a difficult job because a lazy person will find an easy way to do it." — Not me, but I agree.** ▀
