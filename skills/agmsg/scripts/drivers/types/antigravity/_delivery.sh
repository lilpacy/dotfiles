#!/usr/bin/env bash
# antigravity delivery plug — rule-file integration (same shape as gemini).
# rulefile_apply is provided by scripts/lib/delivery-rulefile.sh.
agmsg_delivery_apply() { rulefile_apply "$@"; }
agmsg_delivery_status() { rulefile_status "$@"; }
