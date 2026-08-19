"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import sys
import logging
import urllib.request
from urllib.error import URLError

API_BASE = "https://internal-api.example.com"

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('/var/log/sync_worker.log'),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)

def fetch_orders(cursor):
    url = f"{API_BASE}/orders?cursor={cursor}"
    logger.info(f"Fetching orders: cursor={cursor!r}")
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as res:
            body = res.read()
            logger.debug(f"Response status: {res.status}, size: {len(body)} bytes")
            data = json.loads(body)
            logger.debug(f"Parsed response: {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor')!r}")
            return data
    except URLError as e:
        logger.error(f"URL fetch failed: {e.reason}", exc_info=True)
        raise
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode failed: {e}", exc_info=True)
        raise

def transform(order):
    try:
        order_id = order.get("id")
        logger.debug(f"Transforming order {order_id}")
        items = order.get("items", [])
        total = sum(i.get("price", 0) * i.get("qty", 0) for i in items)
        region = order.get("shipping", {}).get("address", {}).get("region")
        result = {
            "id": order_id,
            "total": total,
            "region": region,
        }
        logger.debug(f"Transform success: id={order_id}, total={total}, region={region}")
        return result
    except (KeyError, TypeError) as e:
        logger.error(f"Transform failed for order: {json.dumps(order)}", exc_info=True)
        raise

def main():
    logger.info("Sync worker started")
    cursor = ""
    synced = 0
    try:
        while True:
            try:
                page = fetch_orders(cursor)
            except Exception as e:
                logger.error(f"Fetch failed after syncing {synced} orders at cursor={cursor!r}", exc_info=True)
                raise

            orders = page.get("orders", [])
            logger.info(f"Processing {len(orders)} orders from this page")
            for order in orders:
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    logger.error(f"Failed to process order {order.get('id')}, synced count at failure: {synced}", exc_info=True)
                    raise

            cursor = page.get("next_cursor")
            logger.debug(f"Page complete. Next cursor: {cursor!r}, total synced: {synced}")
            if not cursor:
                break
        logger.info(f"Sync completed successfully: synced {synced} orders")
    except Exception as e:
        logger.error(f"Sync worker failed with {synced} orders synced", exc_info=True)
        raise

def upload(row):
    url = f"{API_BASE}/warehouse/rows"
    try:
        body = json.dumps(row)
        logger.debug(f"Uploading row: {body}")
        req = urllib.request.Request(
            url,
            data=body.encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req) as res:
            logger.debug(f"Upload success: status={res.status}, row_id={row.get('id')}")
    except URLError as e:
        logger.error(f"Upload failed for row {row.get('id')}: {e.reason}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Upload error for row {row.get('id')}: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.critical(f"Sync worker crashed", exc_info=True)
        sys.exit(1)
