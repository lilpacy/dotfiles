"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import os
import urllib.request

API_BASE = "https://internal-api.example.com"

# cron discards stdout/stderr, so failures need a file that survives the run.
LOG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sync_worker.log")
logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

def fetch_orders(cursor):
    req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read())

def transform(order):
    return {
        "id": order["id"],
        "total": sum(i["price"] * i["qty"] for i in order["items"]),
        "region": order["shipping"]["address"]["region"],
    }

def main():
    cursor = ""
    synced = 0
    while True:
        logging.info("fetching page cursor=%r", cursor)
        page = fetch_orders(cursor)
        for order in page["orders"]:
            try:
                row = transform(order)
                upload(row)
            except Exception:
                logging.exception(
                    "failed on order_id=%r cursor=%r synced_so_far=%d",
                    order.get("id"), cursor, synced,
                )
                raise
            synced += 1
        cursor = page.get("next_cursor")
        if not cursor:
            break
    logging.info("synced %d orders", synced)
    print(f"synced {synced} orders")

def upload(row):
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    urllib.request.urlopen(req)

if __name__ == "__main__":
    try:
        main()
    except Exception:
        logging.exception("sync_worker aborted")
        raise
