# 2 — Two Fact Tables at Different Grains

**What it is.** Instead of forcing sales and inventory into one table, the model uses
**two** fact tables at **two different grains**:

| Fact table | Grain (one row =) |
|---|---|
| `Fact_Sales` | one SKU on one completed transaction |
| `Fact_Inventory_Snapshot` | one location · one SKU · one day |

**Why I chose it.** These answer different questions and are recorded at different
frequencies. Joining them into one table would create a *fan-out*: a single day's inventory
row multiplied by every sale of that SKU that day, silently double-counting both measures.
Keeping them separate means each measure is summable at its own grain, and I join them only
through shared dimensions when a question genuinely needs both (e.g., lost margin = inventory
stockout days × a sales-derived baseline rate).

**What it looks like.** The same store/SKU appears in both, at different resolutions:

```
Fact_Sales (per transaction):
  Date=2025-01-03  Store=2  Product=1  Quantity_Sold=1  Unit_Price=11.79
  Date=2025-01-05  Store=2  Product=1  Quantity_Sold=2  Unit_Price=11.79

Fact_Inventory_Snapshot (per store/SKU/day — every day, sale or not):
  Date=2025-01-15  Store=2  Product=1  Quantity_On_Hand=107
  Date=2025-01-15  Store=2  Product=2  Quantity_On_Hand=93
```

**How I'd defend it.** "Two grains, two tables. If I'd merged them I'd fan-out inventory
across transactions and double-count. They meet only through the shared dimensions."
