# Tmux OGMonk 🧢

OGMonk Tmux Task Manager is a plugin for Tmux that enables you to manage tasks directly within your Tmux sessions using SQLite as the database. This tool allows you to create, view, update, and delete tasks with an intuitive Tmux interface.

<p align="center">
<img src="https://github.com/nedzib/tmux-ogmonk/blob/main/media/img1.png?raw=true" alt="plugin image" />
</p>

## ✨ Features

- **Task Management**: Add, view, update, and delete tasks.
- **Status Indicators**: Visual status indicators for tasks.
- **Date-Specific Tasks**: Manage tasks on a per-day basis (next and someday cards in process).
- **Task Limit**: Prevents adding more than 9 tasks per day, focus on the important things.

## 🗃️ Installation

### Ensure SQLite3 is installed
```sh
sudo apt-get install sqlite3
```

### Using Tmux Plugin Manager (TPM)

1. **Add the plugin to your Tmux configuration (e.g., `~/.tmux.conf`):**
    ```sh
    set -g @plugin 'nedzib/tmux-ogmonk'
    ```

2. **Reload Tmux environment:**
    ```sh
    tmux source-file ~/.tmux.conf
    ```

3. **Press `prefix` + `I` to install the plugin.**

## 🚀 Usage

Just press `prefix` + `r` and `esc` whenever you want to close

## 🙌 Acknowledgments

- [Tmux](https://github.com/tmux/tmux) for providing the terminal multiplexer.
- [SQLite](https://sqlite.org) for the lightweight database engine.

## 📄 License

This project is licensed under the MIT License.
