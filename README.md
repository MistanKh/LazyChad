# LazyChad 🚀

**Luminous & Lazy — The Intelligent Neovim Project.**

LazyChad is a high-performance, aesthetically pleasing Neovim configuration built on the legendary NvChad foundation. It is designed for those who want the beauty of NvChad but with a "hands-off," intelligent toolchain that manages itself.

---

## ✨ Key Features

- **🧠 Intelligent Neural Mappings**: A dynamic toolchain system that live-scans the Mason registry to recommend LSPs, formatters, and linters for every filetype.
- **⚡ Zero Hardcoding**: No more maintaining long lists of tools. LazyChad understands your files and finds the best tools available in real-time.
- **🛡️ Failure Resilience**: Built-in blacklisting prevents repeated installation attempts if a tool (like `csharpier`) fails due to missing system dependencies.
- **💎 Luminous Aesthetics**: Custom "Cyber-Badge" dashboard with real-time intelligence reports and the beautiful Rose Pine theme.
- **🚀 Future-Proof**: Native support for Neovim 0.11+ and the new `vim.lsp.config` API.

---

## 📥 Installation

### 1. Backup your existing config
```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
```

### 2. Clone LazyChad
```bash
git clone https://github.com/your-username/LazyChad ~/.config/nvim
```

### 3. Start Neovim
```bash
nvim
```
LazyChad will automatically bootstrap and prepare your "Intelligent Neural Mappings."

---

## 🛠️ How the Toolchain Works

LazyChad introduces three powerful commands to manage your environment:

- `:LspPick`: Scan Mason for every compatible LSP for your current file and choose one.
- `:FormatPick`: Dynamically discover and set your preferred formatter via `conform.nvim`.
- `:LintPick`: Choose from all available linters supported by `nvim-lint`.

Once you make a choice, **LazyChad remembers it**. The next time you open a file of that type, your tools will start automatically without any prompts.

---

## 🤝 Contributing

Contributions are welcome! If you find a tool that should be marked as "Recommended" or have ideas for new "Built-in" support, feel free to open a PR.

The core logic lives in:
- `lua/configs/picker_utils.lua`: The intelligence engine.
- `lua/configs/lsp_picker.lua`: Dynamic LSP management.
- `lua/configs/selection_ui.lua`: The sequential queueing UI.

---

## 💖 Credits

LazyChad is built with passion on the **NvChad** platform. We owe a huge debt of gratitude to the NvChad team for providing the incredible aesthetic foundation and plugin architecture that made this project possible.

Special thanks to:
- [NvChad](https://github.com/NvChad/NvChad)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Mason.nvim](https://github.com/williamboman/mason.nvim)

---

**Built for the lazy, by the luminous.** ▀
