import time
from functools import lru_cache

RATES = {"USD": 1.0, "EUR": 1.08, "JPY": 0.0067}

def fetch_rate(currency):
    return RATES[currency]

@lru_cache(maxsize=1)
def load_schema():
    time.sleep(0.01)  # reads schema file from disk
    return {"fields": ["id", "currency", "amount"]}

def validate_row(row):
    schema = load_schema()
    return all(k in row for k in schema["fields"])

def main():
    rows = [{"id": i, "currency": ["USD", "EUR", "JPY"][i % 3], "amount": i * 10}
            for i in range(300)]
    total = 0.0
    for row in rows:
        if not validate_row(row):
            continue
        total += row["amount"] * fetch_rate(row["currency"])
    print(f"report total: {total:.2f} ({len(rows)} rows)")

if __name__ == "__main__":
    main()
