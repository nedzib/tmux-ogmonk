#!/usr/bin/env bash

DB_FILE="$HOME/.ogmonk_tmux.db"
TODAY=$(date "+%Y-%m-%d")

# Create the database and table if they don't exist
initialize_db() {
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    status INTEGER NOT NULL DEFAULT 0,
    task TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
EOF
}


show_tasks() {
    local tasks=()
    local line_number=0
    local date=$1

    while IFS='|' read -r id status task; do
        line_number=$((line_number + 1))
        case "$status" in
            '0') status_text="󰄰" ;;
            '1') status_text="󱎖" ;;
            '2') status_text="󰄯" ;;
            '3') status_text="󰪌" ;;
            '4') status_text="󱖘" ;;
        esac
        tasks+=("${status_text} ${task}" "${line_number}" "run-shell '$0 toggle ${id} $date'")
    done < <(tasks_by_date "$date")

    prev_date=$(date -d "$date - 1 day" "+%Y-%m-%d")
    next_date=$(date -d "$date + 1 day" "+%Y-%m-%d")


    menu=(
      "$(formatted_date "$date")"
    )

    if [[ ${#tasks[@]} -eq 0 ]]; then
      menu+=("There is no task for this day" "" "")
    else
      menu+=("${tasks[@]}")
    fi

    menu+=(
    ""
    )

    if [[ "$date" == "$TODAY" ]]; then
      menu+=(
      "New task" "n" "run-shell '$0 add'"
    )
    fi

    menu+=(
    "Delete" "d" "run-shell '$0 remove $date'"
    "<< Previous" "h" "run-shell '$0 show $prev_date'"
    )

    if [[ "$date" != "$TODAY" ]]; then
      menu+=("Next >>" "l" "run-shell '$0 show $next_date'")
    fi

    menu+=(
    ""
    "Help" "?" "run-shell '$0 help'"
    )


    tmux display-menu -x C -y C -T "${menu[@]}"
}


formatted_date() {
    date -d "$1" "+%Y-%m-%d"
}

tasks_by_date() {
    local date="$1"
    sqlite3 "$DB_FILE" "SELECT id, status, task FROM tasks WHERE DATE(created_at) = '$date' ORDER BY created_at"
}

task_count_by_date() {
  local date="$1"
  sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE DATE(created_at) = '$date'"
}

add_task() {
    local task_count
    task_count=$(task_count_by_date "$TODAY")

    if [ "$task_count" -ge 9 ]; then
        tmux display-message "You cannot add more than 9 tasks per day."
        $0 show
        return
    fi

    tmux command-prompt -p "New task: " "run-shell 'sqlite3 $DB_FILE \"INSERT INTO tasks (status, task) VALUES (1, \\\"%1\\\")\"; $0 show'"
}

insert_task() {
    sqlite3 "$DB_FILE" "INSERT INTO tasks (task) VALUES ('$1')"
}

remove_task() {
    tmux command-prompt -p "Task number to delete: " "run-shell '$0 delete %1 $1'"
}

delete_task() {
  local line_number="$1"
  local date="$2"
  if [[ -z "$line_number" ]]; then
    echo "Line number not specified."
    return 1
  fi

  local id_to_delete
  id_to_delete=$(sqlite3 "$DB_FILE" "
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) AS row_num 
      FROM tasks WHERE DATE(created_at) = '$date'
      ) WHERE row_num = $line_number
      ")
      if [[ -z "$id_to_delete" ]]; then
        echo "ID not found for line number: $line_number."
        return 1
      fi

      sqlite3 "$DB_FILE" "DELETE FROM tasks WHERE id = $id_to_delete"
      $0 show $date
}

change_status() {
    current_status=$(sqlite3 "$DB_FILE" "SELECT status FROM tasks WHERE id = $1")

    if [ "$current_status" -eq 4 ]; then
        new_status=0
    else
        new_status=$((current_status + 1))
    fi

    sqlite3 "$DB_FILE" "UPDATE tasks SET status = $new_status WHERE id = $1"
    $0 show $2
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
    show_tasks "$TODAY"
}

main() {
    initialize_db
    cmd="$1"
    shift

    case "$cmd" in
        show)
            show_tasks "$@"
            ;;
        add)
            add_task
            ;;
        remove)
            remove_task "$@"
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
            echo "Usage: $0 {show|add|remove|toggle|delete|menu|help}"
            ;;
    esac
}

main "$@"

