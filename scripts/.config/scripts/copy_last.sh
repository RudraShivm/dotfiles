
 last_command=$(fc -ln -1)
 last_output=$(eval "$last_command")
 printf "%s\n%s\n" "$last_command" "$last_output" | wl-copy
 echo "Copied last command and output to clipboard!"
