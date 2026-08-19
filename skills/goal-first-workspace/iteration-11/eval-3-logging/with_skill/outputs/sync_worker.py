"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import urllib.request
import logging
import traceback
import sys

API_BASE = "https://internal-api.example.com"

# File-based logging: cron discards stdout/stderr, so log to file
# Attempt production path first, fall back to working directory
log_path = '/var/log/sync_worker.log'
try:
    file_handler = logging.FileHandler(log_path)
except (PermissionError, IOError):
    # Fallback for non-production/dev environments
    log_path = './sync_worker.log'
    file_handler = logging.FileHandler(log_path)

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        file_handler,
        logging.StreamHandler(sys.stderr),
    ]
)
logger = logging.getLogger(__name__)

def fetch_orders(cursor):
    logger.debug(f"Fetching orders with cursor: {cursor!r}")
    try:
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            body = res.read()
            data = json.loads(body)
            logger.debug(f"Fetched {len(data.get('orders', []))} orders, next_cursor: {data.get('next_cursor')!r}")
            return data
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error while parsing orders response: {e}", exc_info=True)
        raise
    except urllib.error.URLError as e:
        logger.error(f"Network error fetching orders (cursor={cursor!r}): {e}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Unexpected error in fetch_orders (cursor={cursor!r}): {e}", exc_info=True)
        raise

def transform(order):
    try:
        result = {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
        return result
    except KeyError as e:
        logger.error(f"Missing required field in order transform (order_id={order.get('id')}, field={e}): {order}", exc_info=True)
        raise
    except TypeError as e:
        logger.error(f"Type error in order transform (order_id={order.get('id')}): {e}, order={order}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Unexpected error transforming order {order.get('id')}: {e}", exc_info=True)
        raise

def main():
    logger.info("Starting nightly sync")
    cursor = ""
    synced = 0
    try:
        while True:
            page = fetch_orders(cursor)
            orders_count = len(page.get("orders", []))
            logger.info(f"Processing batch with {orders_count} orders (cursor={cursor!r})")

            for idx, order in enumerate(page["orders"]):
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    logger.error(f"Failed to process order {order.get('id')} (batch idx={idx}): {e}", exc_info=True)
                    raise

            cursor = page.get("next_cursor")
            if not cursor:
                logger.info("No more batches (next_cursor empty), completing sync")
                break

        logger.info(f"Sync completed successfully: synced {synced} orders")
    except Exception as e:
        logger.error(f"Sync failed after syncing {synced} orders. Last cursor: {cursor!r}", exc_info=True)
        raise

def upload(row):
    try:
        logger.debug(f"Uploading row: {row}")
        req = urllib.request.Request(
            f"{API_BASE}/warehouse/rows",
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req)
        logger.debug(f"Successfully uploaded row {row.get('id')}")
    except urllib.error.URLError as e:
        logger.error(f"Network error uploading row {row.get('id')}: {e}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Unexpected error uploading row {row.get('id')}: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    main()
