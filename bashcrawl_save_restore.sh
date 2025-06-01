#!/bin/bash

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

# Save the game state
save_bashcrawl_game() {
    local savefile="$1"
    if [[ -z "$savefile" ]]; then
        echo "Usage: save_bashcrawl_game <savefile>"
        return 1
    fi

    local game_root
    game_root=$(find_bashcrawl_root) || {
        echo "Error: Not inside a bashcrawl directory"
        return 1
    }

    local basedir="bashcrawl"
    local parentdir
    parentdir=$(dirname "$game_root")

    # Tar the whole bashcrawl directory from its parent
    tar -czf "${savefile}.tar.gz" -C "$parentdir" "$basedir" || return 1

    # Save necessary environment variables and current working directory
    {
        echo "export I=${I@Q}"
        echo "export HP=${HP@Q}"
        echo "export SAVED_PWD=${PWD@Q}"
    } > "${savefile}.env"

    echo "Game saved as ${savefile}.tar.gz with environment in ${savefile}.env"
}

# Restore the game state
load_bashcrawl_game() {
    local savefile="$1"
    if [[ -z "$savefile" ]]; then
        echo "Usage: load_bashcrawl_game <savefile>"
        return 1
    fi

    if [[ ! -f "${savefile}.tar.gz" || ! -f "${savefile}.env" ]]; then
        echo "Missing save files: ${savefile}.tar.gz or ${savefile}.env"
        return 1
    fi

    # Load the environment
    source "${savefile}.env"

    # Restore the directory
    tar -xzf "${savefile}.tar.gz" -C "$(dirname "$SAVED_PWD")" || return 1

    cd "$SAVED_PWD" || {
        echo "Warning: Could not change to saved directory $SAVED_PWD"
        return 1
    }

    echo "Restored to $PWD with I=$I, HP=$HP"
}
