#!/usr/bin/env bash

# Number of iterations
ITERATIONS=${1:-5}

# Length of the line
LINE_LENGTH=${2:-100}

for i in $(seq 1 $ITERATIONS); do
    # Sleep 2 seconds before writing
    sleep 2

    # Print a long line
    printf "Iteration %03d: " "$i"
    head -c $LINE_LENGTH < /dev/zero | tr '\0' '='
    echo

    # Wait a short moment so the line is visible
    sleep 0.5

    # Move cursor up 1 line and clear it
    printf "\033[1A\033[2K"
done

# Final line
echo "Done!"

