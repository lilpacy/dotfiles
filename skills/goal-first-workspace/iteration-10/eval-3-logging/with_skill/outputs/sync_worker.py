"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import urllib.request
import logging
import traceback
import sys

logging.basicConfig(
    filename="/var/log/sync_worker.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    try:
        logger.debug(f"Fetching orders with cursor={cursor}")
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
            logger.debug(f"Fetched {len(data.get('orders', []))} orders")
            return data
    except Exception as e:
        logger.error(f"fetch_orders failed with cursor={cursor}: {e}", exc_info=True)
        raise

def transform(order):
    try:
        return {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
    except (KeyError, TypeError) as e:
        logger.error(f"transform failed for order {order.get('id', 'unknown')}: {e}, order={json.dumps(order)}", exc_info=True)
        raise

def main():
    cursor = ""
    synced = 0
    try:
        logger.info("Sync started")
        while True:
            try:
                page = fetch_orders(cursor)
            except Exception as e:
                logger.error(f"Sync failed at fetch stage after syncing {synced} orders", exc_info=True)
                raise
            for order in page["orders"]:
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    logger.error(f"Sync failed processing order {order.get('id', 'unknown')} after syncing {synced} orders", exc_info=True)
                    raise
            cursor = page.get("next_cursor")
            if not cursor:
                break
        logger.info(f"Sync completed successfully: synced {synced} orders")
        print(f"synced {synced} orders")
    except Exception as e:
        logger.critical(f"Sync failed with exit code 1 after syncing {synced} orders", exc_info=True)
        sys.exit(1)

def upload(row):
    try:
        logger.debug(f"Uploading row: {json.dumps(row)}")
        req = urllib.request.Request(
            f"{API_BASE}/warehouse/rows",
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req)
        logger.debug(f"Successfully uploaded row {row.get('id')}")
    except Exception as e:
        logger.error(f"upload failed for row {row.get('id')}: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    main()
