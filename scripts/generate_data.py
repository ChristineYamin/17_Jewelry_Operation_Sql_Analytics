from pathlib import Path
import random

import pandas as pd
from faker import Faker

fake = Faker()
random.seed(42)
Faker.seed(42)

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DATA_DIR = PROJECT_DIR / "data" / "raw"

RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)

# -----------------------------
# Data generation settings
# -----------------------------

NUM_CUSTOMERS = 1_000
NUM_SUPPLIERS = 20
NUM_EMPLOYEES = 40
NUM_PRODUCTS = 300
NUM_SALES = 10_000

START_DATE = pd.Timestamp("2024-01-01")
END_DATE = pd.Timestamp("2025-12-31")

BRANCH_IDS = [1, 2, 3, 4, 5]

GOLD_TYPES = {
    1: "24K",
    2: "22K",
    3: "18K",
    4: "14K",
}

CITIES = [
    "Yangon",
    "Mandalay",
    "Naypyidaw",
    "Taunggyi",
    "Mawlamyine",
    "Bago",
    "Pathein",
]

PRODUCT_CATEGORIES = [
    "Ring",
    "Necklace",
    "Bracelet",
    "Earring",
    "Pendant",
    "Bangle",
    "Chain",
]

PAYMENT_METHODS = [
    "Cash",
    "Card",
    "Bank Transfer",
    "Mobile Payment",
]

JOB_TITLES = [
    "Branch Manager",
    "Sales Associate",
    "Senior Sales Associate",
    "Cashier",
]

#--------------------------------------
# Helper Function
#----------------------------------------

def random_date(start_date: pd.Timestamp, end_date: pd.Timestamp) -> pd.Timestamp:
    """Return a random date between two dates"""
    number_of_days = (end_date - start_date).days
    return start_date + pd.Timedelta( days=random.randint(0, number_of_days))

#-----------------------------------
# Generate customers
# ---------------------------------

customers = []
for customer_id in range(1, NUM_CUSTOMERS + 1):
    customers.append(
        {
            "customer_id": customer_id,
            "customer_name": fake.name(),
            "phone": (
                f"09{random.randint(100000000, 999999999)}"
                if random.random() > 0.05
                else None
            ),
            "city" : (
                random.choice(CITIES)
                if random.random() > 0.08
                else None
            ),
            "registration_date": random_date(
                START_DATE - pd.DateOffset(years=3),
                END_DATE,
            ).date(),
        }
    )

customers_df = pd.DataFrame(customers)
customers_df.to_csv(
    RAW_DATA_DIR / "customers.csv",
    index=False,
)

# -----------------------------
# Generate suppliers
# -----------------------------

suppliers = []

for supplier_id in range(1, NUM_SUPPLIERS + 1):
    suppliers.append(
        {
            "supplier_id": supplier_id,
            "supplier_name": f"{fake.unique.company()} Jewelry Supply",
            "city": random.choice(CITIES),
            "phone": (
                f"09{random.randint(100000000, 999999999)}"
                if random.random() > 0.10
                else None
            ),
        }
    )

suppliers_df = pd.DataFrame(suppliers)

suppliers_df.to_csv(
    RAW_DATA_DIR / "suppliers.csv",
    index=False,
)

# -----------------------------
# Generate employees
# -----------------------------

BRANCH_OPENING_DATES = {
    1: pd.Timestamp("2015-03-15"),
    2: pd.Timestamp("2017-06-20"),
    3: pd.Timestamp("2019-09-10"),
    4: pd.Timestamp("2021-01-25"),
    5: pd.Timestamp("2022-08-12"),
}

employees = []
employee_id = 1

for branch_id in BRANCH_IDS:
    branch_job_titles = [
        "Branch Manager",
        "Senior Sales Associate",
        "Cashier",
        "Sales Associate",
        "Sales Associate",
        "Sales Associate",
        "Sales Associate",
        "Sales Associate",
    ]

    for job_title in branch_job_titles:
        employees.append(
            {
                "employee_id": employee_id,
                "employee_name": fake.name(),
                "branch_id": branch_id,
                "job_title": job_title,
                "hire_date": random_date(
                    BRANCH_OPENING_DATES[branch_id],
                    pd.Timestamp("2025-12-31"),
                ).date(),
                "monthly_target": random.randrange(
                    5_000_000,
                    30_000_001,
                    500_000,
                ),
            }
        )

        employee_id += 1

employees_df = pd.DataFrame(employees)

employees_df.to_csv(
    RAW_DATA_DIR / "employees.csv",
    index=False,
)

# -----------------------------
# Generate gold prices
# -----------------------------

GOLD_PURITY_FACTORS = {
    1: 1.00,  # 24K
    2: 0.916, # 22K
    3: 0.750, # 18K
    4: 0.585, # 14K
}

gold_prices = []
current_24k_price = 180_000.0

for price_date in pd.date_range(START_DATE, END_DATE, freq="D"):
    daily_change = random.uniform(-0.004, 0.005)
    current_24k_price *= 1 + daily_change

    for gold_type_id, purity_factor in GOLD_PURITY_FACTORS.items():
        price_per_gram = round(
            current_24k_price * purity_factor,
            -2,
        )

        gold_prices.append(
            {
                "price_date": price_date.date(),
                "gold_type_id": gold_type_id,
                "price_per_gram": price_per_gram,
            }
        )

gold_prices_df = pd.DataFrame(gold_prices)

gold_prices_df.to_csv(
    RAW_DATA_DIR / "gold_prices.csv",
    index=False,
)

# -----------------------------
# Generate products
# -----------------------------

CATEGORY_SETTINGS = {
    "Ring": (2.0, 12.0, 40_000, 180_000),
    "Necklace": (8.0, 40.0, 100_000, 500_000),
    "Bracelet": (5.0, 25.0, 80_000, 350_000),
    "Earring": (1.0, 8.0, 30_000, 150_000),
    "Pendant": (1.0, 10.0, 30_000, 180_000),
    "Bangle": (8.0, 35.0, 100_000, 450_000),
    "Chain": (5.0, 30.0, 80_000, 400_000),
}

average_gold_prices = (
    gold_prices_df
    .groupby("gold_type_id")["price_per_gram"]
    .mean()
    .to_dict()
)

products = []

for product_id in range(1, NUM_PRODUCTS + 1):
    category = random.choice(PRODUCT_CATEGORIES)
    gold_type_id = random.choices(
        population=[1, 2, 3, 4],
        weights=[20, 40, 25, 15],
        k=1,
    )[0]

    min_weight, max_weight, min_charge, max_charge = (
        CATEGORY_SETTINGS[category]
    )

    weight_grams = round(
        random.uniform(min_weight, max_weight),
        2,
    )

    making_charge = round(
        random.uniform(min_charge, max_charge),
        -3,
    )

    estimated_gold_cost = (
        weight_grams * average_gold_prices[gold_type_id]
    )

    cost_price = round(
        estimated_gold_cost + (making_charge * 0.65),
        -2,
    )

    selling_price = round(
        cost_price * random.uniform(1.08, 1.25),
        -2,
    )

    products.append(
        {
            "product_id": product_id,
            "product_name": (
                f"{GOLD_TYPES[gold_type_id]} "
                f"{category} {product_id:03d}"
            ),
            "category": category,
            "gold_type_id": gold_type_id,
            "weight_grams": weight_grams,
            "making_charge": making_charge,
            "cost_price": cost_price,
            "selling_price": selling_price,
            "supplier_id": random.randint(
                1,
                NUM_SUPPLIERS,
            ),
        }
    )

products_df = pd.DataFrame(products)

products_df.to_csv(
    RAW_DATA_DIR / "products.csv",
    index=False,
)

# -----------------------------
# Generate inventory
# -----------------------------

inventory = []
inventory_id = 1

for branch_id in BRANCH_IDS:
    for product_id in range(1, NUM_PRODUCTS + 1):
        reorder_level = random.randint(2, 5)

        inventory.append(
            {
                "inventory_id": inventory_id,
                "branch_id": branch_id,
                "product_id": product_id,
                "stock_quantity": random.randint(0, 15),
                "reorder_level": reorder_level,
                "last_updated": random_date(
                    END_DATE - pd.Timedelta(days=30),
                    END_DATE,
                ).date(),
            }
        )

        inventory_id += 1

inventory_df = pd.DataFrame(inventory)

inventory_df.to_csv(
    RAW_DATA_DIR / "inventory.csv",
    index=False,
)

# -----------------------------
# Generate sales and sale items
# -----------------------------

employee_ids_by_branch = (
    employees_df
    .groupby("branch_id")["employee_id"]
    .apply(list)
    .to_dict()
)

product_price_lookup = (
    products_df
    .set_index("product_id")["selling_price"]
    .to_dict()
)

customer_registration_dates = pd.to_datetime(
    customers_df["registration_date"]
)

sales = []
sale_items = []

sale_item_id = 1

for sale_id in range(1, NUM_SALES + 1):
    branch_id = random.choice(BRANCH_IDS)

    employee_id = random.choice(
        employee_ids_by_branch[branch_id]
    )

    sale_day = random_date(
        START_DATE,
        END_DATE,
    )

    sale_date = sale_day + pd.Timedelta(
        hours=random.randint(9, 19),
        minutes=random.randint(0, 59),
        seconds=random.randint(0, 59),
    )

    # Some customers are walk-in customers with no customer ID
    if random.random() < 0.15:
        customer_id = None
    else:
        eligible_customer_ids = customers_df.loc[
            customer_registration_dates <= sale_day,
            "customer_id",
        ].tolist()

        customer_id = (
            random.choice(eligible_customer_ids)
            if eligible_customer_ids
            else None
        )

    payment_method = random.choices(
        PAYMENT_METHODS,
        weights=[40, 20, 15, 25],
        k=1,
    )[0]

    number_of_items = random.choices(
        population=[1, 2, 3, 4],
        weights=[55, 28, 12, 5],
        k=1,
    )[0]

    selected_product_ids = random.sample(
        range(1, NUM_PRODUCTS + 1),
        number_of_items,
    )

    transaction_subtotal = 0

    for product_id in selected_product_ids:
        quantity = random.choices(
            population=[1, 2, 3],
            weights=[90, 9, 1],
            k=1,
        )[0]

        base_price = product_price_lookup[product_id]

        unit_price = round(
            base_price * random.uniform(0.98, 1.04),
            -2,
        )

        transaction_subtotal += quantity * unit_price

        sale_items.append(
            {
                "sale_item_id": sale_item_id,
                "sale_id": sale_id,
                "product_id": product_id,
                "quantity": quantity,
                "unit_price": unit_price,
            }
        )

        sale_item_id += 1

    # Around 35% of transactions receive a discount
    if random.random() < 0.35:
        discount_rate = random.uniform(0.01, 0.08)

        discount_amount = round(
            transaction_subtotal * discount_rate,
            -2,
        )
    else:
        discount_amount = 0

    sales.append(
        {
            "sale_id": sale_id,
            "customer_id": customer_id,
            "employee_id": employee_id,
            "branch_id": branch_id,
            "sale_date": sale_date,
            "payment_method": payment_method,
            "discount_amount": discount_amount,
        }
    )

sales_df = pd.DataFrame(sales)
sale_items_df = pd.DataFrame(sale_items)
sales_df["customer_id"] = sales_df["customer_id"].astype("Int64")

sales_df.to_csv(
    RAW_DATA_DIR / "sales.csv",
    index=False,
)

sale_items_df.to_csv(
    RAW_DATA_DIR / "sale_items.csv",
    index=False,
)

