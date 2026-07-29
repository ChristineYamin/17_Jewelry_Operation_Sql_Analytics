# Data Dictionary

# Data Dictionary

## branches

| Column | Data Type | Description | Rules |
|---|---|---|---|
| branch_id | INTEGER | Unique branch identifier | Primary key |
| branch_name | VARCHAR(100) | Name of the branch | Required, unique |
| city | VARCHAR(50) | Branch location | Required |
| opening_date | DATE | Date the branch opened | Cannot be a future date |

## customers

| Column | Data Type | Description | Rules |
|---|---|---|---|
| customer_id | INTEGER | Unique customer identifier | Primary key |
| customer_name | VARCHAR(100) | Customer’s full name | Required |
| phone | VARCHAR(30) | Customer contact number | May be missing |
| city | VARCHAR(50) | Customer location | May be missing |
| registration_date | DATE | Date customer registered | Required |

## employees

| Column | Data Type | Description | Rules |
|---|---|---|---|
| employee_id | INTEGER | Unique employee identifier | Primary key |
| employee_name | VARCHAR(100) | Employee’s full name | Required |
| branch_id | INTEGER | Employee’s assigned branch | Foreign key |
| job_title | VARCHAR(50) | Employee role | Required |
| hire_date | DATE | Employment start date | Required |
| monthly_target | DECIMAL(12,2) | Monthly sales target | Must be zero or greater |

## suppliers

| Column | Data Type | Description | Rules |
|---|---|---|---|
| supplier_id | INTEGER | Unique supplier identifier | Primary key |
| supplier_name | VARCHAR(100) | Supplier business name | Required |
| city | VARCHAR(50) | Supplier location | May be missing |
| phone | VARCHAR(30) | Supplier contact number | May be missing |

## gold_types

| Column | Data Type | Description | Rules |
|---|---|---|---|
| gold_type_id | INTEGER | Unique gold-type identifier | Primary key |
| gold_type_name | VARCHAR(30) | Gold purity or type | Required, unique |

Example values:

```text
24K
22K
18K
14K

```

## products

| Column | Data Type | Description | Rules |
|---|---|---|---|
| product_id | INTEGER | Unique product identifier | Primary key |
| product_name | VARCHAR(100) | Jewelry product name | Required |
| category | VARCHAR(50) | Product category | Required |
| gold_type_id | INTEGER | Product’s gold type | Foreign key |
| weight_grams | DECIMAL(10,2) | Product weight in grams | Must be greater than zero |
| making_charge | DECIMAL(12,2) | Manufacturing charge | Must be zero or greater |
| cost_price | DECIMAL(14,2) | Business acquisition cost | Must be greater than zero |
| selling_price | DECIMAL(14,2) | Customer selling price | Must be greater than zero |
| supplier_id | INTEGER | Product supplier | Foreign key |

Example categories:

```text
Ring
Necklace
Bracelet
Earring
Pendant
Bangle
Chain
```

## sales

| Column | Data Type | Description | Rules |
|---|---|---|---|
| sale_id | INTEGER | Unique transaction identifier | Primary key |
| customer_id | INTEGER | Customer making the purchase | Foreign key; may be missing for walk-in customers |
| employee_id | INTEGER | Employee handling the transaction | Foreign key, required |
| branch_id | INTEGER | Branch where the sale occurred | Foreign key, required |
| sale_date | TIMESTAMP | Transaction date and time | Required |
| payment_method | VARCHAR(30) | Method used for payment | Required |
| discount_amount | DECIMAL(12,2) | Transaction-level discount | Must be zero or greater |

Example payment methods:

```text
Cash
Card
Bank Transfer
Mobile Payment
```

## sale_items

| Column | Data Type | Description | Rules |
|---|---|---|---|
| sale_item_id | INTEGER | Unique sale-line identifier | Primary key |
| sale_id | INTEGER | Related sales transaction | Foreign key, required |
| product_id | INTEGER | Product purchased | Foreign key, required |
| quantity | INTEGER | Number of units purchased | Must be greater than zero |
| unit_price | DECIMAL(14,2) | Selling price at the time of purchase | Must be greater than zero |

## inventory

| Column | Data Type | Description | Rules |
|---|---|---|---|
| inventory_id | INTEGER | Unique inventory-record identifier | Primary key |
| branch_id | INTEGER | Branch holding the product | Foreign key, required |
| product_id | INTEGER | Product held in stock | Foreign key, required |
| stock_quantity | INTEGER | Current available quantity | Must be zero or greater |
| reorder_level | INTEGER | Minimum desired stock quantity | Must be zero or greater |
| last_updated | DATE | Latest inventory update date | Required |

The combination of `branch_id` and `product_id` must be unique.

## gold_prices

| Column | Data Type | Description | Rules |
|---|---|---|---|
| price_date | DATE | Date the gold price was recorded | Composite primary key |
| gold_type_id | INTEGER | Gold type being priced | Composite primary key and foreign key |
| price_per_gram | DECIMAL(14,2) | Gold price for one gram | Must be greater than zero |