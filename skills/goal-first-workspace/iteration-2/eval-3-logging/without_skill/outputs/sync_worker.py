"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log.

cron discards stdout/stderr, so all diagnostics go to a file:
  SYNC_WORKER_LOG (default /tmp/sync_worker.log)
"""
import json
import logging
import os
import sys
import urllib.error
import urllib.request

API_BASE = "https://internal-api.example.com"
LOG_PATH = os.environ.get("SYNC_WORKER_LOG", "/tmp/sync_worker.log")

log = logging.getLogger("sync_worker")


def setup_logging():
    logging.basicConfig(
        filename=LOG_PATH,
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )


def _http(req, what):
    try:
        with urllib.request.urlopen(req) as res:
            return res.read()
    except urllib.error.HTTPError as e:
        # response body is the only place the API explains itself
        log.error("%s failed: HTTP %s %s body=%r", what, e.code, e.reason, e.read()[:2000])
        raise
    except urllib.error.URLError as e:
        log.error("%s failed: %s", what, e.reason)
        raise


def fetch_orders(cursor):
    log.info("fetch_orders cursor=%r", cursor)
    return json.loads(_http(urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}"),
                            f"fetch_orders(cursor={cursor!r})"))


def transform(order):
    return {
        "id": order["id"],
        "total": sum(i["price"] * i["qty"] for i in order["items"]),
        "region": order["shipping"]["address"]["region"],
    }


def main():
    setup_logging()
    log.info("start pid=%s log=%s", os.getpid(), LOG_PATH)
    cursor = ""
    synced = 0
    page_no = 0
    try:
        while True:
            page_no += 1
            page = fetch_orders(cursor)
            orders = page["orders"]
            log.info("page %d cursor=%r orders=%d synced_so_far=%d",
                     page_no, cursor, len(orders), synced)
            for order in orders:
                order_id = order.get("id") if isinstance(order, dict) else None
                try:
                    row = transform(order)
                    upload(row)
                except Exception:
                    # the failing record itself is what we cannot get from prod otherwise
                    log.exception("order failed page=%d cursor=%r id=%r synced_so_far=%d raw=%s",
                                  page_no, cursor, order_id, synced,
                                  json.dumps(order, default=str)[:2000])
                    raise
                synced += 1
            cursor = page.get("next_cursor")
            log.info("page %d done next_cursor=%r synced=%d", page_no, cursor, synced)
            if not cursor:
                break
    except Exception as e:
        # stack trace is already logged at the point of failure; keep this a summary
        log.error("aborted after %d orders, page=%d cursor=%r: %s: %s",
                  synced, page_no, cursor, type(e).__name__, e)
        sys.exit(1)
    log.info("synced %d orders in %d pages", synced, page_no)


def upload(row):
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    _http(req, f"upload(id={row.get('id')!r})")


if __name__ == "__main__":
    main()
