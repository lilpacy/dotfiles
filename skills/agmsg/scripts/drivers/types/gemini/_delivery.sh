#!/usr/bin/env bash
# gemini delivery plug — rule-file integration (markdown rules file).
#
# Sourced by delivery.sh (in its function context) to override the default
# agmsg_delivery_apply. rulefile_apply is provided by
# scripts/lib/delivery-rulefile.sh, which delivery.sh sources first.
agmsg_delivery_apply() { rulefile_apply "$@"; }
agmsg_delivery_status() { rulefile_status "$@"; }
