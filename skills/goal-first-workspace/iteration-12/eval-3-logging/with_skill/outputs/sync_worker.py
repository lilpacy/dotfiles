"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import os
import urllib.error
import urllib.request

API_BASE = "https://internal-api.example.com"

# cron discards stdout/stderr, so diagnostics must land in a file to survive.
LOG_FILE = os.environ.get("SYNC_WORKER_LOG_FILE", "/tmp/sync_worker.log")
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("sync_worker")

def fetch_orders(cursor):
    logger.info("fetching page cursor=%r", cursor)
    req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
    try:
        with urllib.request.urlopen(req) as res:
            page = json.loads(res.read())
    except urllib.error.HTTPError as e:
        logger.error("fetch_orders failed cursor=%r status=%s body=%s", cursor, e.code, e.read())
        raise
    except Exception:
        logger.exception("fetch_orders failed cursor=%r", cursor)
        raise
    logger.debug(
        "fetched %d orders next_cursor=%r",
        len(page.get("orders", [])), page.get("next_cursor"),
    )
    return page

def transform(order):
    try:
        return {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
    except Exception:
        logger.exception("transform failed order=%r", order)
        raise

def main():
    cursor = ""
    synced = 0
    logger.info("sync started")
    try:
        while True:
            page = fetch_orders(cursor)
            for order in page["orders"]:
                row = transform(order)
                upload(row)
                synced += 1
            cursor = page.get("next_cursor")
            if not cursor:
                break
    except Exception:
        logger.exception("sync aborted after synced=%d", synced)
        raise
    logger.info("sync finished synced=%d", synced)
    print(f"synced {synced} orders")

def upload(row):
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        logger.error("upload failed row=%r status=%s body=%s", row, e.code, e.read())
        raise
    except Exception:
        logger.exception("upload failed row=%r", row)
        raise

if __name__ == "__main__":
    main()
