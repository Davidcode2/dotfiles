#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
# If all your bars have ipc enabled, you can also use 
# polybar-msg cmd quit

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar main and bar2
echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log
polybar -r main 2>&1 | tee -a /tmp/polybar1.log & disown

echo "Bars launched..."
