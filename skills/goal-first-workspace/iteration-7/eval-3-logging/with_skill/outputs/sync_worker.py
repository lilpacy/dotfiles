"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import sys
import traceback
import urllib.request
from urllib.error import HTTPError, URLError

API_BASE = "https://internal-api.example.com"

def log_error(msg):
    print(f"[ERROR] {msg}", file=sys.stderr)

def fetch_orders(cursor):
    url = f"{API_BASE}/orders?cursor={cursor}"
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as res:
            body = res.read()
            return json.loads(body)
    except HTTPError as e:
        log_error(f"fetch_orders: HTTP {e.code} from {url}: {e.reason}")
        raise
    except URLError as e:
        log_error(f"fetch_orders: network error from {url}: {e.reason}")
        raise
    except json.JSONDecodeError as e:
        log_error(f"fetch_orders: invalid JSON from {url}: {e}")
        raise
    except Exception as e:
        log_error(f"fetch_orders: unexpected error from {url}: {type(e).__name__}: {e}")
        traceback.print_exc(file=sys.stderr)
        raise

def transform(order):
    try:
        return {
            "id": order["id"],
            "total": sum(i["price"] * i["qty"] for i in order["items"]),
            "region": order["shipping"]["address"]["region"],
        }
    except KeyError as e:
        log_error(f"transform: missing key {e} in order {order.get('id', 'unknown')}: {order}")
        raise
    except (TypeError, ValueError) as e:
        log_error(f"transform: invalid data type in order {order.get('id', 'unknown')}: {type(e).__name__}: {e}")
        raise
    except Exception as e:
        log_error(f"transform: unexpected error in order {order.get('id', 'unknown')}: {type(e).__name__}: {e}")
        traceback.print_exc(file=sys.stderr)
        raise

def main():
    cursor = ""
    synced = 0
    try:
        while True:
            print(f"[INFO] fetching page with cursor={cursor[:20] if cursor else 'start'}")
            try:
                page = fetch_orders(cursor)
            except Exception as e:
                log_error(f"main: fetch_orders failed, stopping after {synced} synced orders")
                raise

            if "orders" not in page:
                log_error(f"main: missing 'orders' key in response: {page}")
                raise KeyError("'orders' not found in API response")

            orders = page["orders"]
            print(f"[INFO] received {len(orders)} orders")

            for i, order in enumerate(orders):
                try:
                    row = transform(order)
                    upload(row)
                    synced += 1
                except Exception as e:
                    log_error(f"main: failed to process order {i} of page (id={order.get('id', 'unknown')}), skipping")
                    continue

            cursor = page.get("next_cursor")
            print(f"[INFO] page complete: synced {synced} total, next_cursor={bool(cursor)}")
            if not cursor:
                break

        print(f"[INFO] synced {synced} orders successfully")
    except Exception as e:
        log_error(f"main: fatal error after syncing {synced} orders: {type(e).__name__}")
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
        urllib.request.urlopen(req)
    except HTTPError as e:
        log_error(f"upload: HTTP {e.code} to {url}: {e.reason}")
        raise
    except URLError as e:
        log_error(f"upload: network error to {url}: {e.reason}")
        raise
    except Exception as e:
        log_error(f"upload: unexpected error to {url}: {type(e).__name__}: {e}")
        traceback.print_exc(file=sys.stderr)
        raise

if __name__ == "__main__":
    main()
