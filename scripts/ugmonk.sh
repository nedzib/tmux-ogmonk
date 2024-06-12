#!/usr/bin/env bash

TASK_FILE="$HOME/.ogmonk_tmux.txt"

# Crear el archivo si no existe
if [ ! -f "$TASK_FILE" ]; then
    touch "$TASK_FILE"
fi

show_tasks() {
    local tasks=()
    local line_number=0

    while IFS='|' read -r date status task; do
        line_number=$((line_number + 1))
        case "$status" in
            u) status_text="󰄰" ;;
            p) status_text="󱎖" ;;
            d) status_text="󰄯" ;;
            t) status_text="󰪌" ;;
            r) status_text="󱖘" ;;
        esac
        tasks+=("${status_text} ${task}" "${line_number}" "run-shell '$0 toggle ${line_number}'")
    done < "$TASK_FILE"

    tmux display-menu -x R -y S -T "$(date "+%d-%m-%Y") - ogMonk" \
        "${tasks[@]}" \
        "" \
        "New thing" "n" "run-shell '$0 add'" \
        "Delete" "d" "run-shell '$0 remove'" \
        "Help" "?" "run-shell '$0 help'"
}

add_task() {
    tmux command-prompt -p "Nueva tarea: " "run-shell 'echo \"$(date "+%d-%m-%Y")|u|%1\" >> $TASK_FILE; $0 show'"
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
    if ! [[ "$line_number" =~ ^[0-9]+$ ]]; then
        echo "Número de línea inválido."
        return 1
    fi
    sed -i.bak "${line_number}d" "$TASK_FILE" && rm "$TASK_FILE.bak"
    $0 show
}

change_status() {
    local line_number="$1"
    local current_line
    current_line=$(sed -n "${line_number}p" "$TASK_FILE")

    IFS='|' read -r date status task <<< "$current_line"

    case "$status" in
        u) new_status="p" ;;
        p) new_status="d" ;;
        d) new_status="t" ;;
        t) new_status="r" ;;
        r) new_status="u" ;;
    esac

    sed -i.bak "${line_number}s/.*/${date}|${new_status}|${task}/" "$TASK_FILE" && rm "$TASK_FILE.bak"
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

