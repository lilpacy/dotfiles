import csv
import sys

def main():
    rows = []
    skipped = 0
    with open("data.csv") as f:
        reader = csv.reader(f, delimiter=";")
        header = next(reader)
        for lineno, line in enumerate(reader, start=2):
            try:
                name, amount, category = line
                rows.append((name, int(amount), category))
            except ValueError as e:
                skipped += 1
                print(f"skip line {lineno}: {line!r} ({e})", file=sys.stderr)
    with open("output.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["name", "amount", "category"])
        for r in rows:
            w.writerow(r)
    print(f"wrote {len(rows)} rows, skipped {skipped}")

if __name__ == "__main__":
    main()
