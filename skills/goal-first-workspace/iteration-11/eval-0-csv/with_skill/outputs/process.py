import csv

def main():
    rows = []
    skipped = 0
    with open("data.csv") as f:
        reader = csv.reader(f)
        header = next(reader)
        for line_num, line in enumerate(reader, start=2):
            try:
                name, amount, category = line
                rows.append((name, int(amount), category))
            except (ValueError, IndexError):
                print(f"Skipped line {line_num}: {line}")
                skipped += 1
    with open("output.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["name", "amount", "category"])
        for r in rows:
            w.writerow(r)
    print(f"wrote {len(rows)} rows, skipped {skipped} broken rows")

if __name__ == "__main__":
    main()
