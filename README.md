This is the desktop I wanted, my friends liked it and have made the repo public to create scripts to install on their system.

You can use it if you want.

needs the following:

- [https://github.com/shashstormer/miyagi-service](https://github.com/shashstormer/miyagi-service)
- [https://github.com/shashstormer/arch-board](https://github.com/shashstormer/arch-board)
- Needs background [https://github.com/shashstormer/comm_ipc](https://github.com/shashstormer/comm_ipc) server running on default settings.

This has been built for myself and my friends.

AI HAS BEEN SIGNIFICANTLY USED.

## Installation (Arch Linux)

### One-line Installation

**Bash / Zsh**:
```bash
bash <(curl -s https://raw.githubusercontent.com/shashstormer/miyagi-shell/master/install.sh)
```

**Fish**:
```fish
bash (curl -s https://raw.githubusercontent.com/shashstormer/miyagi-shell/master/install.sh | psub)
```

> **Note**: The installation script will clone the repository into `~/.config/stormapps/miyagi-shell`, create a symlink to `~/.config/quickshell/miyagi`, and automatically install both `miyagi-service` and `arch-board`.

### Manual Installation

To install Miyagi Shell into `~/.config/stormapps/miyagi-shell`:

```bash
# Clone and install
git clone https://github.com/shashstormer/miyagi-shell.git ~/.config/stormapps/miyagi-shell
cd ~/.config/stormapps/miyagi-shell
./install.sh
```

Or run `install.sh` directly within the cloned repository:
```bash
./install.sh
```

## Running & Updates

- **Start Shell**:
  ```bash
  ./start.sh
  ```
  Or via Quickshell:
  ```bash
  quickshell -p ~/.config/quickshell/miyagi
  ```

- **Update Shell**:
  ```bash
  ./update.sh
  ```

