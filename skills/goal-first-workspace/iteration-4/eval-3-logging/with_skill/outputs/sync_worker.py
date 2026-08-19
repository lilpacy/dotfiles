"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import logging
import urllib.request

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

API_BASE = "https://internal-api.example.com"
API_TIMEOUT = 30

def fetch_orders(cursor):
    url = f"{API_BASE}/orders?cursor={cursor}"
    try:
        req = urllib.request.Request(url)
        logger.info(f"fetch_orders: calling {url}")
        with urllib.request.urlopen(req, timeout=API_TIMEOUT) as res:
            body = res.read()
            data = json.loads(body)
            logger.info(f"fetch_orders: got {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor', 'none')}")
            return data
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, KeyError) as e:
        logger.error(f"fetch_orders: failed for cursor={cursor}", exc_info=True)
        raise

def transform(order):
    try:
        return {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
    except (KeyError, TypeError) as e:
        logger.error(f"transform: failed for order_id={order.get('id', 'unknown')}", exc_info=True)
        raise

def main():
    cursor = ""
    synced = 0
    try:
        while True:
            logger.info(f"main: fetching page, cursor={cursor}, synced_so_far={synced}")
            page = fetch_orders(cursor)
            for order in page["orders"]:
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    logger.warning(f"main: skipping order due to {type(e).__name__}", exc_info=False)
                    continue
            cursor = page.get("next_cursor")
            if not cursor:
                break
        logger.info(f"main: sync completed successfully, synced {synced} orders")
    except Exception as e:
        logger.error(f"main: sync failed after {synced} orders", exc_info=True)
        raise

def upload(row):
    url = f"{API_BASE}/warehouse/rows"
    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        logger.debug(f"upload: posting row_id={row.get('id')}")
        urllib.request.urlopen(req, timeout=API_TIMEOUT)
    except (urllib.error.URLError, urllib.error.HTTPError) as e:
        logger.error(f"upload: failed for row_id={row.get('id')}", exc_info=True)
        raise

if __name__ == "__main__":
    main()
