#!/usr/bin/env bash
# claude-code delivery plug.
#
# Uses the default JSON event-hooks apply (agmsg_delivery_apply). On enable
# (monitor/both) it emits the in-session Monitor directive so a running Claude
# Code session starts streaming immediately. Sourced into delivery.sh's context,
# so emit_monitor_directive is in scope. Args: on_enable <mode> <type> <project>.
agmsg_delivery_on_enable() {
  echo "Future sessions: SessionStart hook will auto-launch the watcher."
  emit_monitor_directive "$2" "$3"
}
