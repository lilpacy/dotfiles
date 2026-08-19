"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import urllib.request
from urllib.error import HTTPError, URLError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    logger.info(f"Fetching orders with cursor={cursor or 'START'}")
    req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
    try:
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
            logger.info(f"Fetched {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor', 'NONE')}")
            return data
    except HTTPError as e:
        logger.error(f"HTTP error fetching orders: status={e.code}, body={e.read().decode()}")
        raise
    except URLError as e:
        logger.error(f"Network error fetching orders: {e.reason}")
        raise

def transform(order):
    try:
        return {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
    except KeyError as e:
        logger.error(f"Transform failed for order {order.get('id', '?')}: missing key {e}, order={order}")
        raise

def main():
    cursor = ""
    synced = 0
    try:
        logger.info("Sync started")
        while True:
            page = fetch_orders(cursor)
            for order in page["orders"]:
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    logger.error(f"Failed to sync order {order.get('id', '?')}: {e}")
                    raise
            cursor = page.get("next_cursor")
            if not cursor:
                logger.info("No more pages, sync complete")
                break
        logger.info(f"Sync completed successfully: synced {synced} orders")
        print(f"synced {synced} orders")
    except Exception as e:
        logger.error(f"Sync failed after {synced} orders: {e}", exc_info=True)
        raise

def upload(row):
    logger.debug(f"Uploading row: {row}")
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as res:
            logger.debug(f"Upload successful for row {row.get('id')}")
    except HTTPError as e:
        logger.error(f"HTTP error uploading row {row.get('id')}: status={e.code}, body={e.read().decode()}")
        raise
    except URLError as e:
        logger.error(f"Network error uploading row {row.get('id')}: {e.reason}")
        raise

if __name__ == "__main__":
    main()
