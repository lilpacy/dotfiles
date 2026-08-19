"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import sys
import traceback
import urllib.request

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)]
)

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    try:
        logging.debug(f"Fetching orders with cursor={cursor!r}")
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
        logging.debug(f"Fetched page with {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor')!r}")
        return data
    except Exception as e:
        logging.error(f"Failed to fetch orders (cursor={cursor!r}): {e}", exc_info=True)
        raise

def transform(order):
    try:
        result = {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
        return result
    except (KeyError, TypeError) as e:
        logging.error(f"Failed to transform order {order.get('id', 'unknown')}: {e}. Order data: {order}", exc_info=True)
        raise

def main():
    cursor = ""
    synced = 0
    try:
        while True:
            page = fetch_orders(cursor)
            for order in page["orders"]:
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception:
                    logging.error(f"Failed to sync order {order.get('id', 'unknown')}, continuing with next order")
                    continue
            cursor = page.get("next_cursor")
            if not cursor:
                break
        logging.info(f"Sync completed successfully: synced {synced} orders")
        print(f"synced {synced} orders")
    except Exception as e:
        logging.critical(f"Sync failed after syncing {synced} orders: {e}", exc_info=True)
        raise

def upload(row):
    try:
        logging.debug(f"Uploading row: {row}")
        req = urllib.request.Request(
            f"{API_BASE}/warehouse/rows",
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req)
        logging.debug(f"Uploaded row {row.get('id')}")
    except Exception as e:
        logging.error(f"Failed to upload row {row.get('id', 'unknown')}: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    main()
