"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import sys
import traceback
import urllib.request
import urllib.error

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    try:
        print(f"[fetch_orders] cursor={cursor}", file=sys.stderr)
        req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
            print(f"[fetch_orders] got {len(data.get('orders', []))} orders", file=sys.stderr)
            return data
    except urllib.error.HTTPError as e:
        print(f"[fetch_orders] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"[fetch_orders] error: {type(e).__name__}: {e}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
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
        print(f"[transform] missing key {e} in order {order.get('id', 'unknown')}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"[transform] error: {type(e).__name__}: {e}, order={order}", file=sys.stderr)
        raise

def main():
    cursor = ""
    synced = 0
    try:
        print("[main] starting sync", file=sys.stderr)
        while True:
            page = fetch_orders(cursor)
            for order in page["orders"]:
                row = transform(order)
                upload(row)
                synced += 1
            cursor = page.get("next_cursor")
            if not cursor:
                break
        print(f"[main] sync completed: {synced} orders", file=sys.stderr)
        print(f"synced {synced} orders")
    except Exception as e:
        print(f"[main] fatal error after {synced} orders: {type(e).__name__}: {e}", file=sys.stderr)
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
    except urllib.error.HTTPError as e:
        print(f"[upload] HTTP {e.code} for row {row.get('id')}: {e.read().decode()}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"[upload] error: {type(e).__name__}: {e}, row={row}", file=sys.stderr)
        raise

if __name__ == "__main__":
    main()
