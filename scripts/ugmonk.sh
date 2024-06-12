#!/usr/bin/env bash

DB_FILE="$HOME/.ogmonk_tmux.db"
TODAY=$(date "+%d-%m-%Y")

# Crear la base de datos y la tabla si no existen
initialize_db() {
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    status TEXT NOT NULL,
    task TEXT NOT NULL,
    created_at TEXT NOT NULL
);
EOF
}

show_tasks() {
    local tasks=()
    local line_number=0

    while IFS='|' read -r id date status task created_at; do
        line_number=$((line_number + 1))
        case "$status" in
            u) status_text="󰄰" ;;
            p) status_text="󱎖" ;;
            d) status_text="󰄯" ;;
            t) status_text="󰪌" ;;
            r) status_text="󱖘" ;;
        esac
        tasks+=("${status_text} ${task}" "${line_number}" "run-shell '$0 toggle ${id}'")
    done < <(sqlite3 "$DB_FILE" "SELECT id, date, status, task, created_at FROM tasks WHERE date = '$TODAY' ORDER BY created_at")

    tmux display-menu -x R -y S -T "$(date "+%Y-%m-%d")" \
        "${tasks[@]}" \
        "" \
        "New thing" "n" "run-shell '$0 add'" \
        "Delete" "d" "run-shell '$0 remove'" \
        "" \
        "Help" "?" "run-shell '$0 help'"
}

add_task() {
    tmux command-prompt -p "Nueva tarea: " "run-shell 'sqlite3 $DB_FILE \"INSERT INTO tasks (date, status, task, created_at) VALUES (\\\"$TODAY\\\", \\\"u\\\", \\\"%1\\\", \\\"$(date "+%Y-%m-%d %H:%M:%S")\\\")\"; $0 show'"
}

remove_task() {
    tmux command-prompt -p "Número de tarea a eliminar: " "run-shell '$0 delete %1'"
}

delete_task() {
    local line_number="$1"
    if [[ -z "$line_number" ]]; then
        echo "Número de línea no especificado."
        return 1
    fi

    local id_to_delete
    id_to_delete=$(sqlite3 "$DB_FILE" "SELECT id FROM (SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) AS row_num FROM tasks WHERE date = '$TODAY') WHERE row_num = $line_number")

    if [[ -z "$id_to_delete" ]]; then
        echo "ID no encontrado para el número de línea: $line_number."
        return 1
    fi

    sqlite3 "$DB_FILE" "DELETE FROM tasks WHERE id = $id_to_delete"
    $0 show
}

change_status() {
    local id="$1"
    local current_task
    current_task=$(sqlite3 "$DB_FILE" "SELECT date, status, task FROM tasks WHERE id = $id AND date = '$TODAY'")

    IFS='|' read -r date status task <<< "$current_task"

    case "$status" in
        u) new_status="p" ;;
        p) new_status="d" ;;
        d) new_status="t" ;;
        t) new_status="r" ;;
        r) new_status="u" ;;
    esac

    sqlite3 "$DB_FILE" "UPDATE tasks SET status = '$new_status' WHERE id = $id AND date = '$TODAY'"
    $0 show
}

help_ogmonk() {
    tmux display-popup -w 50% -h 50% "echo 'Symbols and their meanings:
󰄰 - Pending
󱎖 - In Progress
󰄯 - Done
󰪌 - Meeting
󱖘 - Delegated

press esc'"
    $0 show
}

popup_menu() {
    show_tasks
}

main() {
    initialize_db
    cmd="$1"
    shift

    case "$cmd" in
        show)
            show_tasks
            ;;
        add)
            add_task
            ;;
        remove)
            remove_task
            ;;
        toggle)
            change_status "$@"
            ;;
        delete)
            delete_task "$@"
            ;;
        menu)
            popup_menu
            ;;
        help)
            help_ogmonk
            ;;
        *)
            echo "Uso: $0 {show|add|remove|toggle|delete|menu|help}"
            ;;
    esac
}

main "$@"

