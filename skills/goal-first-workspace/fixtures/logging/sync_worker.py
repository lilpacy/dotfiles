"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log."""
import json
import urllib.request

API_BASE = "https://internal-api.example.com"

def fetch_orders(cursor):
    req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read())

def transform(order):
    return {
        "id": order["id"],
        "total": sum(i["price"] * i["qty"] for i in order["items"]),
        "region": order["shipping"]["address"]["region"],
    }

def main():
    cursor = ""
    synced = 0
    while True:
        page = fetch_orders(cursor)
        for order in page["orders"]:
            row = transform(order)
            upload(row)
            synced += 1
        cursor = page.get("next_cursor")
        if not cursor:
            break
    print(f"synced {synced} orders")

def upload(row):
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    urllib.request.urlopen(req)

if __name__ == "__main__":
    main()
