#!/bin/bash

PROJECT_DIR="$1"
BUILD_CMD="$2"
RUN_CMD="$3"
DISPLAY_VAR="$4"
WAYLAND_DISPLAY_VAR="$5"
USE_TWO_PANES="$6"
BUILD_TOOL="$7"

cd "$PROJECT_DIR" || exit 1

filter_output() {
  local tool="$1"
  
  case "$tool" in
    maven)
      awk '
        BEGIN { in_output = 0 }
        /^\[INFO\] --- exec:/ { in_output = 1; next }
        /^\[INFO\] ---------/ { in_output = 0; next }
        /^\[INFO\] BUILD SUCCESS/ { in_output = 0; next }
        /^\[INFO\] Total time:/ { next }
        /^\[INFO\] Finished at:/ { next }
        in_output && !/^\[INFO\]/ && !/^\[WARNING\]/ && !/^\[DEBUG\]/ { print; fflush() }
      '
      ;;
    gradle)
      awk '
        BEGIN { in_output = 0 }
        /^> Task :run$/ { in_output = 1; next }
        /^BUILD SUCCESSFUL/ { in_output = 0; next }
        /^[0-9]+ actionable task/ { next }
        in_output && !/^> / { print; fflush() }
      '
      ;;
    *)
      cat
      ;;
  esac
}

if [ "$USE_TWO_PANES" = "false" ]; then
  echo "=== BUILD OUTPUT ==="
  eval "$BUILD_CMD"
  BUILD_EXIT=$?

  if [ $BUILD_EXIT -ne 0 ]; then
    echo
    echo "✗ Build failed (exit code: $BUILD_EXIT)"
    echo "Press Enter to close..."
    read
    exit 1
  fi

  echo
  echo "✓ Build successful"
  echo
  echo "=== PROGRAM OUTPUT ==="
  DISPLAY="$DISPLAY_VAR" WAYLAND_DISPLAY="$WAYLAND_DISPLAY_VAR" stdbuf -o0 -e0 eval "$RUN_CMD" 2>&1 | filter_output "$BUILD_TOOL"
  echo
  echo "Press Enter to close..."
  read
  exit 0
fi

echo "=== BUILD OUTPUT ==="
eval "$BUILD_CMD"
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
  echo
  echo "✗ Build failed (exit code: $BUILD_EXIT)"
  echo "Press Enter to close..."
  read
  exit 1
fi

echo
echo "✓ Build successful"
echo "Press Enter to close both panes..."

BUILD_PANE="$TMUX_PANE"

RUN_PANE=$(tmux split-window -t "$TMUX_PANE" -v -p 70 -P -F "#{pane_id}" \
  "cd '$PROJECT_DIR' && DISPLAY='$DISPLAY_VAR' WAYLAND_DISPLAY='$WAYLAND_DISPLAY_VAR' \
  BUILD_PANE='$BUILD_PANE' && \
  BUILD_TOOL='$BUILD_TOOL' && \
  filter_output() {
    local tool=\"\$1\"
    case \"\$tool\" in
      maven)
        awk '
          BEGIN { in_output = 0 }
          /^\[INFO\] --- exec:/ { in_output = 1; next }
          /^\[INFO\] ---------/ { in_output = 0; next }
          /^\[INFO\] BUILD SUCCESS/ { in_output = 0; next }
          /^\[INFO\] Total time:/ { next }
          /^\[INFO\] Finished at:/ { next }
          in_output && !/^\[INFO\]/ && !/^\[WARNING\]/ && !/^\[DEBUG\]/ { print; fflush() }
        '
        ;;
      gradle)
        awk '
          BEGIN { in_output = 0 }
          /^> Task :run$/ { in_output = 1; next }
          /^BUILD SUCCESSFUL/ { in_output = 0; next }
          /^[0-9]+ actionable task/ { next }
          in_output && !/^> / { print; fflush() }
        '
        ;;
      *)
        cat
        ;;
    esac
  } && \
  echo '=== PROGRAM OUTPUT ===' && \
  stdbuf -o0 -e0 eval \"$RUN_CMD\" 2>&1 | filter_output \"\$BUILD_TOOL\"; \
  echo && echo 'Press Enter to close both panes...'; \
  read; \
  tmux kill-pane -t \"\$BUILD_PANE\" 2>/dev/null; \
  exit 0")

read
tmux kill-pane -t "$RUN_PANE" 2>/dev/null
exit 0
