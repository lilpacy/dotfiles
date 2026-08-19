import csv

def main():
    rows = []
    with open("data.csv") as f:
        reader = csv.reader(f)
        header = next(reader)
        for line in reader:
            try:
                name, amount, category = line
                rows.append((name, int(amount), category))
            except ValueError:
                pass
    with open("output.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["name", "amount", "category"])
        for r in rows:
            w.writerow(r)
    print(f"wrote {len(rows)} rows")

if __name__ == "__main__":
    main()
