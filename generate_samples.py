import csv
import random
import os

# Seed for reproducibility (remove or change for different results each run)
random.seed(42)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(SCRIPT_DIR, "houses.csv")

# ---------------------------------------------------------------------------
# Read existing data
# ---------------------------------------------------------------------------
existing_rows: list[list[int]] = []
with open(CSV_PATH, "r", newline="") as f:
    reader = csv.reader(f)
    for row in reader:
        if row:
            existing_rows.append([int(v) for v in row])

print(f"Existing samples: {len(existing_rows)}")
for r in existing_rows:
    print(f"  area={r[0]}, rooms={r[1]}, bathrooms={r[2]}, age={r[3]}, price={r[4]}")

# ---------------------------------------------------------------------------
# Helper – estimate a realistic price from the other features
# ---------------------------------------------------------------------------
def estimate_price(area: int, rooms: int, bathrooms: int, age: int) -> int:
    """
    Simple linear model loosely fitted to the six original samples:
        price ≈ 2.2 * area + 20 * rooms + 15 * bathrooms - 3 * age
    A small random noise term is added so prices aren't perfectly deterministic.
    """
    base = 2.2 * area + 20 * rooms + 15 * bathrooms - 3 * age
    noise = random.gauss(0, base * 0.05)  # ±5 % noise
    price = base + noise
    # Round to nearest 10 and clamp to a sensible minimum
    price = max(50, round(price / 10) * 10)
    return int(price)

# ---------------------------------------------------------------------------
# Generate new random samples
# ---------------------------------------------------------------------------
NUM_NEW_SAMPLES = 10000  # will bring total to 50

new_rows: list[list[int]] = []
for _ in range(NUM_NEW_SAMPLES):
    area = random.randint(60, 350)

    # rooms loosely scales with area
    if area < 100:
        rooms = random.choice([1, 2, 2, 3])
    elif area < 180:
        rooms = random.choice([2, 3, 3, 4])
    elif area < 260:
        rooms = random.choice([3, 4, 4, 5])
    else:
        rooms = random.choice([4, 5, 5, 6])

    # bathrooms ≤ rooms, usually rooms//2 to rooms-1
    bathrooms = random.randint(max(1, rooms // 2), rooms)

    age = random.randint(0, 50)

    price = estimate_price(area, rooms, bathrooms, age)

    new_rows.append([area, rooms, bathrooms, age, price])

# ---------------------------------------------------------------------------
# Write everything back (original + new) to the CSV
# ---------------------------------------------------------------------------
all_rows = existing_rows + new_rows

with open(CSV_PATH, "w", newline="") as f:
    writer = csv.writer(f)
    for row in all_rows:
        writer.writerow(row)

print(f"\nGenerated {NUM_NEW_SAMPLES} new samples.")
print(f"Total samples now: {len(all_rows)}")
print("\nFirst 10 new samples:")
for r in new_rows[:10]:
    print(f"  area={r[0]}, rooms={r[1]}, bathrooms={r[2]}, age={r[3]}, price={r[4]}")

print(f"\nData saved to {CSV_PATH}")
