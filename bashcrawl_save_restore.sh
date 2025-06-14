#!/bin/bash

saveI() {
    export saveI=$I
}
loadI() {
    export I=$saveI
}
getI() {
    echo $saveI
}

hint() {
    if [[ -x ".hint" ]]; then
        ./.hint
    else
        echo "No hint available."
    fi
}

# Traverse upward to find the 'bashcrawl' directory root
find_bashcrawl_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ "$(basename "$dir")" == "bashcrawl" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

save_bashcrawl_game() {
    local player_name="$1"
    if [[ -z "$player_name" ]]; then
        echo "Usage: save_bashcrawl_game <player_name>"
        return 1
    fi

    local game_root
    game_root=$(find_bashcrawl_root) || {
        echo "Error: Not inside a bashcrawl directory"
        return 1
    }

    local basedir
    basedir=$(basename "$game_root")
    local parentdir
    parentdir=$(dirname "$game_root")

    local savefile="${parentdir}/${player_name}_save_$(date +%F_%H-%M-%S)"

    # Create tarball excluding hidden or backup files (optional: customize)
    tar --exclude='*.tar.gz' --exclude='*.env' -czf "${savefile}.tar.gz" -C "$parentdir" "$basedir" || return 1

    # Save necessary environment variables and current working directory
    {
        echo "export I=${I@Q}"
        echo "export HP=${HP@Q}"
        echo "export SAVED_PWD=${PWD@Q}"
    } > "${savefile}.env"

    echo "Game saved as ${savefile}.tar.gz with environment in ${savefile}.env"
}

restore_bashcrawl_game() {
    local basefile="$1"
    if [[ -z "$basefile" ]]; then
        echo "Usage: restore_bashcrawl_game <path/to/savefile (without .tar.gz)>"
        return 1
    fi

    local tarfile="${basefile}.tar.gz"
    local envfile="${basefile}.env"

    if [[ ! -f "$tarfile" ]]; then
        echo "Error: Archive $tarfile not found."
        return 1
    fi

    if [[ ! -f "$envfile" ]]; then
        echo "Warning: Environment file $envfile not found — proceeding without it."
    fi

    # Extract archive to the current directory (or prompt if unsafe)
    echo "This will extract the saved game into the current directory:"
    pwd
    read -rp "Proceed? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        echo "Aborted."
        return 1
    }

    tar -xzf "$tarfile" || {
        echo "Error: Failed to extract archive."
        return 1
    }

    # Load saved environment variables if available
    if [[ -f "$envfile" ]]; then
        # shellcheck disable=SC1090
        source "$envfile"
        echo "Environment restored: I=$I, HP=$HP"
    fi

    if [[ -n "$SAVED_PWD" && -d "$SAVED_PWD" ]]; then
        cd "$SAVED_PWD" || echo "Warning: Could not return to saved directory."
    fi

    echo "Game restored successfully."
}

