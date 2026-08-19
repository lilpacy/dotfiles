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

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    try:
        logging.debug(f"fetch_orders: cursor={cursor}")
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            body = res.read()
            logging.debug(f"fetch_orders: received {len(body)} bytes")
            data = json.loads(body)
            logging.debug(f"fetch_orders: got {len(data.get('orders', []))} orders, next_cursor={data.get('next_cursor')}")
            return data
    except json.JSONDecodeError as e:
        logging.error(f"fetch_orders: JSON decode error: {e}, body={body[:500]}")
        raise
    except Exception as e:
        logging.error(f"fetch_orders: {type(e).__name__}: {e}", exc_info=True)
        raise

def transform(order):
    try:
        logging.debug(f"transform: order_id={order.get('id')}")
        result = {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
        logging.debug(f"transform: order_id={order.get('id')} -> total={result['total']}, region={result['region']}")
        return result
    except KeyError as e:
        logging.error(f"transform: missing key {e} in order_id={order.get('id')}, order={json.dumps(order)[:500]}")
        raise
    except (TypeError, ValueError) as e:
        logging.error(f"transform: type/value error in order_id={order.get('id')}: {e}, order={json.dumps(order)[:500]}")
        raise
    except Exception as e:
        logging.error(f"transform: {type(e).__name__} in order_id={order.get('id')}: {e}", exc_info=True)
        raise

def main():
    try:
        logging.info("sync started")
        cursor = ""
        synced = 0
        while True:
            try:
                page = fetch_orders(cursor)
                logging.info(f"processing page with {len(page.get('orders', []))} orders, cursor={cursor}")
                for order in page["orders"]:
                    row = transform(order)
                    upload(row)
                    synced += 1
                cursor = page.get("next_cursor")
                if not cursor:
                    logging.info(f"no next_cursor, ending pagination loop")
                    break
            except Exception as e:
                logging.error(f"page processing failed at cursor={cursor}, synced={synced} so far: {type(e).__name__}: {e}", exc_info=True)
                raise
        logging.info(f"sync completed successfully: synced {synced} orders")
        print(f"synced {synced} orders")
    except Exception as e:
        logging.critical(f"sync failed: {type(e).__name__}: {e}", exc_info=True)
        sys.exit(1)

def upload(row):
    try:
        logging.debug(f"upload: row_id={row.get('id')}")
        req = urllib.request.Request(
            f"{API_BASE}/warehouse/rows",
            data=json.dumps(row).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req) as res:
            logging.debug(f"upload: row_id={row.get('id')} -> status {res.status}")
    except Exception as e:
        logging.error(f"upload: failed for row_id={row.get('id')}, row={json.dumps(row)}: {type(e).__name__}: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    main()
