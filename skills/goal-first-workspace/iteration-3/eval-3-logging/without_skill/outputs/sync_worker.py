"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import sys
import urllib.request

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
)
log = logging.getLogger(__name__)

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    log.info(f"Fetching orders with cursor={cursor!r}")
    try:
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
            log.info(f"Fetched page with {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor')!r}")
            return data
    except Exception as e:
        log.exception(f"Failed to fetch orders (cursor={cursor!r})")
        raise

def transform(order):
    try:
        row = {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
        return row
    except KeyError as e:
        log.error(f"Transform failed for order {order.get('id', '?')}: missing key {e}")
        raise
    except Exception as e:
        log.exception(f"Transform failed for order {order.get('id', '?')}")
        raise

def main():
    log.info("Sync started")
    cursor = ""
    synced = 0
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
        log.info(f"Sync completed successfully: synced {synced} orders")
        print(f"synced {synced} orders")
    except Exception as e:
        log.error(f"Sync failed after {synced} orders")
        raise

def upload(row):
    try:
        req = urllib.request.Request(
            f"{API_BASE}/warehouse/rows",
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req)
    except Exception as e:
        log.exception(f"Upload failed for row {row.get('id', '?')}")
        raise

if __name__ == "__main__":
    main()
