#!/usr/bin/env python3
"""Generate a synthetic dbt manifest.json + run_results.json for the demo project.

Domain: Beanstalk Coffee Co. — an indie coffee roaster web store.

This script is the source of truth. Edit MODELS / SOURCES / SEEDS / EXPOSURES
(and BUILD_TIMES) below and re-run to regenerate everything under
fixtures/demo-coffee-shop/target/.

manifest.json is shaped to satisfy the narrow subset of fields Lineage's
ManifestParser actually decodes (see Lineage/Model/Manifest.swift), padded with
a few extra dbt-standard keys (fqn, checksum, etc.) so the file resembles a
real `dbt run` artifact.

run_results.json carries per-node execution_time so the app's "color by Build
Time" feature has a meaningful spread (cheap views at the staging layer → slow
analytics rollups at the sink). Ephemeral intermediate models are intentionally
omitted — dbt doesn't actually build them, they're inlined as CTEs.
"""

from __future__ import annotations

import datetime as dt
import json
import pathlib
import random
import uuid
from typing import Any

PACKAGE = "beanstalk_coffee"
ADAPTER = "duckdb"
DBT_VERSION = "1.10.4"
DATABASE = "beanstalk"
INVOCATION_ID = "f7b1f8c4-1c41-4d2d-8a3a-5f7c2c6c2b00"
GENERATED_AT = "2026-05-19T13:00:00.000000Z"
RUN_STARTED_AT = dt.datetime(2026, 5, 19, 12, 58, 0, tzinfo=dt.timezone.utc)


# ---------------------------------------------------------------------------
# Column shorthand helpers
# ---------------------------------------------------------------------------

def col(name: str, dtype: str, desc: str = "") -> dict[str, Any]:
    return {"name": name, "data_type": dtype, "description": desc}


CUSTOMER_COLS = [
    col("customer_id", "bigint", "Surrogate primary key for the customer."),
    col("email", "varchar", "Lowercased customer email address."),
    col("first_name", "varchar"),
    col("last_name", "varchar"),
    col("country_code", "varchar", "ISO 3166-1 alpha-2 country code from shipping address."),
    col("signup_date", "date", "Date the customer created their account."),
]

ORDER_COLS = [
    col("order_id", "bigint", "Surrogate primary key for the order."),
    col("customer_id", "bigint", "FK to customers."),
    col("ordered_at", "timestamp", "Timestamp the customer placed the order."),
    col("status", "varchar", "One of: placed, paid, fulfilled, refunded, cancelled."),
    col("order_total_usd", "numeric(12,2)", "Order grand total in USD, incl. tax + shipping."),
    col("subtotal_usd", "numeric(12,2)", "Order subtotal in USD, excl. tax + shipping."),
]

ORDER_ITEM_COLS = [
    col("order_item_id", "bigint"),
    col("order_id", "bigint"),
    col("product_id", "bigint"),
    col("quantity", "integer"),
    col("unit_price_usd", "numeric(10,2)"),
    col("line_total_usd", "numeric(12,2)"),
]

PRODUCT_COLS = [
    col("product_id", "bigint"),
    col("sku", "varchar", "Stock-keeping unit code, e.g. ETH-12OZ-WHOLE."),
    col("product_name", "varchar"),
    col("category_key", "varchar", "Joins to product_categories.category_key."),
    col("unit_price_usd", "numeric(10,2)"),
    col("is_subscription_eligible", "boolean"),
]

SUBSCRIPTION_COLS = [
    col("subscription_id", "bigint"),
    col("customer_id", "bigint"),
    col("product_id", "bigint"),
    col("status", "varchar", "active, paused, churned, reactivated"),
    col("cadence", "varchar", "weekly, biweekly, monthly"),
    col("started_at", "timestamp"),
    col("ended_at", "timestamp", "Null while active."),
]

INVENTORY_COLS = [
    col("snapshot_id", "bigint"),
    col("snapshot_date", "date"),
    col("sku", "varchar"),
    col("on_hand_units", "integer"),
    col("reorder_threshold", "integer"),
]

CHARGE_COLS = [
    col("charge_id", "varchar", "Stripe charge ID, e.g. ch_3OabcDEF..."),
    col("order_id", "bigint", "Linked back to shop orders via metadata."),
    col("amount_usd", "numeric(12,2)"),
    col("currency", "varchar"),
    col("status", "varchar", "succeeded, failed, refunded"),
    col("charged_at", "timestamp"),
    col("payment_method_type", "varchar"),
]

WEB_EVENT_COLS = [
    col("event_id", "varchar"),
    col("anonymous_id", "varchar"),
    col("event_name", "varchar", "page_view, add_to_cart, checkout_start, purchase, etc."),
    col("page_path", "varchar"),
    col("occurred_at", "timestamp"),
    col("utm_source", "varchar"),
    col("utm_medium", "varchar"),
    col("utm_campaign", "varchar"),
]


# ---------------------------------------------------------------------------
# Sources (raw, untouched operational data)
# ---------------------------------------------------------------------------
# Tuple: (source_name, table_name, schema, description, columns)

SOURCES: list[tuple[str, str, str, str, list[dict[str, Any]]]] = [
    ("shop_db", "customers", "raw_ecommerce",
        "Customer records from the storefront database (one row per registered customer).",
        CUSTOMER_COLS),
    ("shop_db", "orders", "raw_ecommerce",
        "One row per order placed through the storefront, in any status.",
        ORDER_COLS),
    ("shop_db", "order_items", "raw_ecommerce",
        "Line items within each order. Multiple rows per order.",
        ORDER_ITEM_COLS),
    ("shop_db", "products", "raw_ecommerce",
        "Product catalog: coffees, espresso blends, brewing accessories, gift cards.",
        PRODUCT_COLS),
    ("shop_db", "subscriptions", "raw_ecommerce",
        "Recurring coffee subscriptions. One row per subscription instance.",
        SUBSCRIPTION_COLS),
    ("shop_db", "inventory_snapshots", "raw_ecommerce",
        "Daily inventory counts per SKU pulled from the warehouse system.",
        INVENTORY_COLS),
    ("stripe", "charges", "raw_stripe",
        "All Stripe charges, successful and failed, replicated via Fivetran.",
        CHARGE_COLS),
    ("segment", "web_events", "raw_segment",
        "Clickstream events from the marketing site and storefront, via Segment.",
        WEB_EVENT_COLS),
]


# ---------------------------------------------------------------------------
# Seeds (CSV lookup tables checked into the dbt project)
# ---------------------------------------------------------------------------
# Tuple: (name, description, columns, tags)

SEEDS: list[tuple[str, str, list[dict[str, Any]], list[str]]] = [
    ("country_codes",
        "ISO 3166-1 country codes mapped to region and continent for geo rollups.",
        [
            col("country_code", "varchar", "ISO 3166-1 alpha-2 code."),
            col("country_name", "varchar"),
            col("region", "varchar", "UN geoscheme region."),
            col("continent", "varchar"),
        ],
        ["reference"]),
    ("product_categories",
        "Category hierarchy lookup keyed by category_key (e.g. coffee/single-origin/ethiopia).",
        [
            col("category_key", "varchar"),
            col("category_name", "varchar"),
            col("parent_category", "varchar"),
        ],
        ["reference"]),
]


# ---------------------------------------------------------------------------
# Models — staging, intermediate, marts/*
# ---------------------------------------------------------------------------
# Tuple: (name, folder_segments, materialized, description, depends_on, tags, columns)
#
# `folder_segments` is everything between `models/` and `<name>.sql` —
# e.g. ["staging", "shop"] becomes models/staging/shop/<name>.sql.
# `depends_on` is a list of full unique_id strings.

S = "source"
M = "model"
SD = "seed"


def sref(source_name: str, table: str) -> str:
    return f"source.{PACKAGE}.{source_name}.{table}"


def mref(name: str) -> str:
    return f"model.{PACKAGE}.{name}"


def seedref(name: str) -> str:
    return f"seed.{PACKAGE}.{name}"


MODELS: list[tuple[str, list[str], str, str, list[str], list[str], list[dict[str, Any]]]] = [
    # --- Staging ---------------------------------------------------------
    ("stg_shop__customers", ["staging", "shop"], "view",
        "Cleaned customer records: lowercased emails, parsed names, deduped on customer_id.",
        [sref("shop_db", "customers")],
        ["pii", "staging"],
        CUSTOMER_COLS),
    ("stg_shop__orders", ["staging", "shop"], "view",
        "Storefront orders with status normalized and order totals cast to numeric.",
        [sref("shop_db", "orders")],
        ["staging"],
        ORDER_COLS),
    ("stg_shop__order_items", ["staging", "shop"], "view",
        "Order line items with line totals recomputed for consistency.",
        [sref("shop_db", "order_items")],
        ["staging"],
        ORDER_ITEM_COLS),
    ("stg_shop__products", ["staging", "shop"], "view",
        "Active product catalog with category_key normalized for joining to product_categories.",
        [sref("shop_db", "products")],
        ["staging"],
        PRODUCT_COLS),
    ("stg_shop__subscriptions", ["staging", "shop"], "view",
        "Subscription records with cadence parsed and statuses normalized.",
        [sref("shop_db", "subscriptions")],
        ["staging", "subscription"],
        SUBSCRIPTION_COLS),
    ("stg_shop__inventory_snapshots", ["staging", "shop"], "view",
        "Daily inventory snapshots, deduped per (snapshot_date, sku).",
        [sref("shop_db", "inventory_snapshots")],
        ["staging", "ops"],
        INVENTORY_COLS),
    ("stg_stripe__charges", ["staging", "stripe"], "view",
        "Stripe charges with amounts converted from cents to USD numeric.",
        [sref("stripe", "charges")],
        ["staging", "finance"],
        CHARGE_COLS),
    ("stg_segment__web_events", ["staging", "segment"], "view",
        "Segment clickstream events with bot traffic filtered out.",
        [sref("segment", "web_events")],
        ["staging", "marketing"],
        WEB_EVENT_COLS),

    # --- Intermediate ----------------------------------------------------
    ("int_orders__line_items_joined", ["intermediate"], "ephemeral",
        "Orders joined with their line items and product metadata. One row per order_item, denormalized.",
        [mref("stg_shop__orders"), mref("stg_shop__order_items"), mref("stg_shop__products")],
        ["intermediate"],
        [
            col("order_id", "bigint"),
            col("order_item_id", "bigint"),
            col("customer_id", "bigint"),
            col("product_id", "bigint"),
            col("sku", "varchar"),
            col("category_key", "varchar"),
            col("quantity", "integer"),
            col("unit_price_usd", "numeric(10,2)"),
            col("line_total_usd", "numeric(12,2)"),
            col("ordered_at", "timestamp"),
        ]),
    ("int_subscriptions__active_periods", ["intermediate"], "ephemeral",
        "Subscription lifecycles flattened into [started_at, ended_at) active windows for time-bound aggregations.",
        [mref("stg_shop__subscriptions")],
        ["intermediate", "subscription"],
        [
            col("subscription_id", "bigint"),
            col("customer_id", "bigint"),
            col("product_id", "bigint"),
            col("active_from", "timestamp"),
            col("active_to", "timestamp", "Exclusive upper bound; null while active."),
            col("cadence", "varchar"),
        ]),
    ("int_web_sessions__sessionized", ["intermediate"], "ephemeral",
        "Web events grouped into sessions (30-minute inactivity gap) with first-touch UTM attribution.",
        [mref("stg_segment__web_events")],
        ["intermediate", "marketing"],
        [
            col("session_id", "varchar"),
            col("anonymous_id", "varchar"),
            col("session_started_at", "timestamp"),
            col("session_ended_at", "timestamp"),
            col("event_count", "integer"),
            col("first_touch_utm_source", "varchar"),
            col("first_touch_utm_campaign", "varchar"),
            col("converted", "boolean", "Whether the session contained a purchase event."),
        ]),
    ("int_customers__order_summary", ["intermediate"], "ephemeral",
        "One row per customer with first/last order date, total orders, and lifetime gross revenue.",
        [mref("stg_shop__customers"), mref("stg_shop__orders")],
        ["intermediate", "pii"],
        [
            col("customer_id", "bigint"),
            col("first_order_at", "timestamp"),
            col("most_recent_order_at", "timestamp"),
            col("lifetime_orders", "integer"),
            col("lifetime_gross_revenue_usd", "numeric(14,2)"),
        ]),

    # --- Marts / Core (dimensions) --------------------------------------
    ("dim_customers", ["marts", "core"], "table",
        "Customer dimension with lifetime aggregates and geographic enrichment from country_codes.",
        [mref("stg_shop__customers"), mref("int_customers__order_summary"), seedref("country_codes")],
        ["core", "pii"],
        [
            col("customer_id", "bigint", "Primary key."),
            col("email", "varchar"),
            col("first_name", "varchar"),
            col("last_name", "varchar"),
            col("country_code", "varchar"),
            col("country_name", "varchar"),
            col("region", "varchar"),
            col("continent", "varchar"),
            col("signup_date", "date"),
            col("first_order_at", "timestamp"),
            col("lifetime_orders", "integer"),
            col("lifetime_gross_revenue_usd", "numeric(14,2)"),
        ]),
    ("dim_products", ["marts", "core"], "table",
        "Product dimension joined to the category hierarchy.",
        [mref("stg_shop__products"), seedref("product_categories")],
        ["core"],
        [
            col("product_id", "bigint"),
            col("sku", "varchar"),
            col("product_name", "varchar"),
            col("category_key", "varchar"),
            col("category_name", "varchar"),
            col("parent_category", "varchar"),
            col("unit_price_usd", "numeric(10,2)"),
            col("is_subscription_eligible", "boolean"),
        ]),
    ("dim_subscriptions", ["marts", "core"], "table",
        "Subscription dimension with one row per subscription, including its active windows.",
        [mref("stg_shop__subscriptions"), mref("int_subscriptions__active_periods")],
        ["core", "subscription"],
        [
            col("subscription_id", "bigint"),
            col("customer_id", "bigint"),
            col("product_id", "bigint"),
            col("current_status", "varchar"),
            col("cadence", "varchar"),
            col("first_active_at", "timestamp"),
            col("last_active_at", "timestamp"),
        ]),

    # --- Marts / Finance (facts) ----------------------------------------
    ("fct_orders", ["marts", "finance"], "table",
        "One row per order with customer attribution and revenue split out.",
        [mref("stg_shop__orders"), mref("int_orders__line_items_joined"), mref("dim_customers")],
        ["finance"],
        [
            col("order_id", "bigint"),
            col("customer_id", "bigint"),
            col("ordered_at", "timestamp"),
            col("status", "varchar"),
            col("item_count", "integer"),
            col("subtotal_usd", "numeric(12,2)"),
            col("order_total_usd", "numeric(12,2)"),
        ]),
    ("fct_order_items", ["marts", "finance"], "table",
        "One row per line item, with product and category attribution for revenue-by-SKU analysis.",
        [mref("int_orders__line_items_joined"), mref("dim_products")],
        ["finance"],
        [
            col("order_item_id", "bigint"),
            col("order_id", "bigint"),
            col("product_id", "bigint"),
            col("sku", "varchar"),
            col("category_key", "varchar"),
            col("quantity", "integer"),
            col("unit_price_usd", "numeric(10,2)"),
            col("line_total_usd", "numeric(12,2)"),
            col("ordered_at", "timestamp"),
        ]),
    ("fct_payments", ["marts", "finance"], "table",
        "Stripe charges joined to shop orders, with failed and refunded charges retained for reconciliation.",
        [mref("stg_stripe__charges"), mref("fct_orders")],
        ["finance"],
        [
            col("charge_id", "varchar"),
            col("order_id", "bigint"),
            col("customer_id", "bigint"),
            col("amount_usd", "numeric(12,2)"),
            col("status", "varchar"),
            col("payment_method_type", "varchar"),
            col("charged_at", "timestamp"),
        ]),

    # --- Marts / Marketing ----------------------------------------------
    ("fct_web_sessions", ["marts", "marketing"], "table",
        "One row per web session with first-touch attribution and customer linkage where identified.",
        [mref("int_web_sessions__sessionized"), mref("dim_customers")],
        ["marketing"],
        [
            col("session_id", "varchar"),
            col("anonymous_id", "varchar"),
            col("customer_id", "bigint", "Nullable when the session was anonymous."),
            col("session_started_at", "timestamp"),
            col("session_ended_at", "timestamp"),
            col("event_count", "integer"),
            col("first_touch_utm_source", "varchar"),
            col("first_touch_utm_campaign", "varchar"),
            col("converted", "boolean"),
        ]),

    # --- Marts / Subscription -------------------------------------------
    ("fct_subscription_events", ["marts", "subscription"], "table",
        "Transitions on the subscription lifecycle (start, pause, churn, reactivate) with elapsed days since prior event.",
        [mref("stg_shop__subscriptions"), mref("int_subscriptions__active_periods"),
         mref("dim_customers"), mref("dim_subscriptions")],
        ["subscription"],
        [
            col("event_id", "bigint"),
            col("subscription_id", "bigint"),
            col("customer_id", "bigint"),
            col("event_type", "varchar", "started, paused, churned, reactivated."),
            col("occurred_at", "timestamp"),
            col("days_since_previous_event", "integer"),
        ]),

    # --- Marts / Analytics (rollups) ------------------------------------
    ("mart_daily_revenue", ["marts", "analytics"], "table",
        "Daily gross/net revenue rollup combining order revenue with refunds applied from payments.",
        [mref("fct_orders"), mref("fct_payments")],
        ["finance", "daily"],
        [
            col("revenue_date", "date"),
            col("orders_placed", "integer"),
            col("gross_revenue_usd", "numeric(14,2)"),
            col("refunds_usd", "numeric(14,2)"),
            col("net_revenue_usd", "numeric(14,2)"),
        ]),
    ("mart_customer_lifetime_value", ["marts", "analytics"], "table",
        "Customer-level LTV combining one-time order revenue with subscription revenue projections.",
        [mref("dim_customers"), mref("fct_orders"), mref("fct_subscription_events")],
        ["pii", "daily"],
        [
            col("customer_id", "bigint"),
            col("cohort_month", "date"),
            col("lifetime_orders", "integer"),
            col("lifetime_revenue_usd", "numeric(14,2)"),
            col("projected_subscription_revenue_usd", "numeric(14,2)"),
            col("ltv_usd", "numeric(14,2)"),
        ]),
    ("mart_product_performance", ["marts", "analytics"], "table",
        "Product-level performance: units sold, revenue, reorder rate, and current inventory days-on-hand.",
        [mref("dim_products"), mref("fct_order_items")],
        ["daily"],
        [
            col("product_id", "bigint"),
            col("sku", "varchar"),
            col("units_sold_l30", "integer", "Units sold in trailing 30 days."),
            col("revenue_l30_usd", "numeric(14,2)"),
            col("reorder_rate", "numeric(5,4)", "Share of customers who purchased this SKU more than once."),
        ]),
    ("mart_acquisition_funnel", ["marts", "analytics"], "table",
        "Marketing funnel by acquisition channel: sessions → checkouts → first orders → repeat orders.",
        [mref("fct_web_sessions"), mref("fct_orders")],
        ["marketing", "daily"],
        [
            col("acquisition_channel", "varchar"),
            col("sessions", "integer"),
            col("checkouts_started", "integer"),
            col("first_orders", "integer"),
            col("repeat_orders_l90", "integer"),
            col("conversion_rate", "numeric(5,4)"),
        ]),
]


# ---------------------------------------------------------------------------
# Exposures (downstream consumers of the warehouse, e.g. BI dashboards)
# ---------------------------------------------------------------------------
# Tuple: (name, type, description, depends_on, tags)

EXPOSURES: list[tuple[str, str, str, list[str], list[str]]] = [
    ("executive_kpi_dashboard", "dashboard",
        "Weekly executive review: revenue, LTV, and acquisition headline metrics.",
        [mref("mart_daily_revenue"),
         mref("mart_customer_lifetime_value"),
         mref("mart_acquisition_funnel")],
        []),
    ("marketing_attribution_sheet", "analysis",
        "Channel attribution Google Sheet refreshed weekly by the marketing team.",
        [mref("mart_acquisition_funnel"), mref("fct_web_sessions")],
        ["marketing"]),
    ("ops_inventory_tracker", "application",
        "Operations app for the warehouse team to flag SKUs trending below reorder threshold.",
        [mref("stg_shop__inventory_snapshots"), mref("dim_products")],
        ["ops"]),
]


# ---------------------------------------------------------------------------
# Synthetic build times — fed into run_results.json so Lineage's "color by
# Build Time" feature has a visible spread on the demo. Ephemeral
# intermediates aren't built and are omitted. Exposures appear with the dbt
# convention status="no-op" + ~4ms execution_time.
# ---------------------------------------------------------------------------
# Keyed by node "short name" (everything after the resource_type prefix).
# Units are seconds.

BUILD_TIMES: dict[str, float] = {
    # Seeds: CSVs loaded into a small table.
    "country_codes": 0.05,
    "product_categories": 0.07,

    # Staging (views): CREATE VIEW is fast, dataset-size-dependent.
    "stg_shop__customers": 0.18,
    "stg_shop__orders": 0.34,
    "stg_shop__order_items": 0.42,
    "stg_shop__products": 0.12,
    "stg_shop__subscriptions": 0.15,
    "stg_shop__inventory_snapshots": 0.28,
    "stg_stripe__charges": 0.31,
    "stg_segment__web_events": 0.47,

    # Marts / core (dims): joins + light enrichment.
    "dim_customers": 2.1,
    "dim_products": 1.4,
    "dim_subscriptions": 1.8,

    # Marts / finance (facts): heavier joins.
    "fct_orders": 5.6,
    "fct_order_items": 4.2,
    "fct_payments": 2.3,

    # Marts / marketing & subscription.
    "fct_web_sessions": 4.8,
    "fct_subscription_events": 2.7,

    # Marts / analytics rollups: most expensive — aggregate across the warehouse.
    "mart_daily_revenue": 6.9,
    "mart_customer_lifetime_value": 11.4,
    "mart_product_performance": 7.6,
    "mart_acquisition_funnel": 8.3,
}

# Models that aren't physically built by `dbt run` (ephemeral CTEs). Omitted
# from run_results.json entirely, matching real dbt behavior.
EPHEMERAL_MODELS: set[str] = {
    "int_orders__line_items_joined",
    "int_subscriptions__active_periods",
    "int_web_sessions__sessionized",
    "int_customers__order_summary",
}

EXPOSURE_NOOP_SECONDS = 0.004


# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------

def make_columns(cols: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for c in cols:
        out[c["name"]] = {
            "name": c["name"],
            "description": c.get("description", ""),
            "meta": {},
            "data_type": c["data_type"],
            "constraints": [],
            "quote": None,
            "tags": [],
        }
    return out


def base_config(materialized: str, tags: list[str], enabled: bool = True) -> dict[str, Any]:
    return {
        "enabled": enabled,
        "alias": None,
        "schema": None,
        "database": None,
        "tags": tags,
        "meta": {},
        "group": None,
        "materialized": materialized,
        "persist_docs": {},
        "post-hook": [],
        "pre-hook": [],
        "quoting": {},
        "column_types": {},
        "full_refresh": None,
        "unique_key": None,
        "on_schema_change": "ignore",
        "grants": {},
        "packages": [],
        "docs": {"show": True, "node_color": None},
        "contract": {"enforced": False, "alias_types": True, "checksum": None},
        "access": "protected",
    }


def fake_checksum() -> dict[str, str]:
    return {"name": "sha256", "checksum": "0" * 64}


def build_model_node(name: str, folder: list[str], materialized: str, description: str,
                     depends_on: list[str], tags: list[str], columns: list[dict[str, Any]]) -> dict[str, Any]:
    unique_id = mref(name)
    original_file_path = "/".join(["models"] + folder + [f"{name}.sql"])
    path = "/".join(folder + [f"{name}.sql"])
    schema = folder[-1] if folder else "main"
    return {
        "database": DATABASE,
        "schema": schema,
        "name": name,
        "resource_type": "model",
        "package_name": PACKAGE,
        "path": path,
        "original_file_path": original_file_path,
        "unique_id": unique_id,
        "fqn": [PACKAGE] + folder + [name],
        "alias": name,
        "checksum": fake_checksum(),
        "config": base_config(materialized, tags),
        "tags": tags,
        "description": description,
        "columns": make_columns(columns),
        "meta": {},
        "group": None,
        "docs": {"show": True, "node_color": None},
        "patch_path": None,
        "build_path": None,
        "deferred": False,
        "unrendered_config": {"materialized": materialized},
        "created_at": 1716130800.0,
        "config_call_dict": {},
        "relation_name": f'"{DATABASE}"."{schema}"."{name}"',
        "raw_code": "",
        "language": "sql",
        "refs": [],
        "sources": [],
        "metrics": [],
        "depends_on": {"macros": [], "nodes": depends_on},
        "compiled_path": None,
        "compiled": False,
        "compiled_code": None,
        "extra_ctes_injected": False,
        "extra_ctes": [],
        "contract": {"enforced": False, "checksum": None},
        "access": "protected",
        "constraints": [],
        "version": None,
        "latest_version": None,
        "deprecation_date": None,
    }


def build_seed_node(name: str, description: str, columns: list[dict[str, Any]], tags: list[str]) -> dict[str, Any]:
    unique_id = seedref(name)
    original_file_path = f"seeds/{name}.csv"
    return {
        "database": DATABASE,
        "schema": "seeds",
        "name": name,
        "resource_type": "seed",
        "package_name": PACKAGE,
        "path": f"{name}.csv",
        "original_file_path": original_file_path,
        "unique_id": unique_id,
        "fqn": [PACKAGE, "seeds", name],
        "alias": name,
        "checksum": fake_checksum(),
        "config": base_config("seed", tags),
        "tags": tags,
        "description": description,
        "columns": make_columns(columns),
        "meta": {},
        "group": None,
        "docs": {"show": True, "node_color": None},
        "patch_path": None,
        "build_path": None,
        "deferred": False,
        "unrendered_config": {},
        "created_at": 1716130800.0,
        "config_call_dict": {},
        "relation_name": f'"{DATABASE}"."seeds"."{name}"',
        "depends_on": {"macros": [], "nodes": []},
        "root_path": "",
        "raw_code": "",
    }


def build_source(source_name: str, table: str, schema: str, description: str,
                 columns: list[dict[str, Any]]) -> dict[str, Any]:
    unique_id = f"source.{PACKAGE}.{source_name}.{table}"
    return {
        "database": DATABASE,
        "schema": schema,
        "name": table,
        "resource_type": "source",
        "package_name": PACKAGE,
        "path": f"models/staging/{source_name}/_sources.yml",
        "original_file_path": f"models/staging/{source_name}/_sources.yml",
        "unique_id": unique_id,
        "fqn": [PACKAGE, "staging", source_name, source_name, table],
        "source_name": source_name,
        "source_description": f"{source_name} source system.",
        "loader": "",
        "identifier": table,
        "quoting": {"database": False, "schema": False, "identifier": False, "column": None},
        "loaded_at_field": None,
        "freshness": {"warn_after": {"count": None, "period": None},
                       "error_after": {"count": None, "period": None}, "filter": None},
        "external": None,
        "description": description,
        "columns": make_columns(columns),
        "meta": {},
        "source_meta": {},
        "tags": [],
        "config": {"enabled": True},
        "patch_path": None,
        "unrendered_config": {},
        "relation_name": f'"{DATABASE}"."{schema}"."{table}"',
        "created_at": 1716130800.0,
    }


def build_exposure(name: str, etype: str, description: str, depends_on: list[str],
                   tags: list[str]) -> dict[str, Any]:
    unique_id = f"exposure.{PACKAGE}.{name}"
    return {
        "name": name,
        "resource_type": "exposure",
        "package_name": PACKAGE,
        "path": "_exposures.yml",
        "original_file_path": "models/_exposures.yml",
        "unique_id": unique_id,
        "fqn": [PACKAGE, name],
        "type": etype,
        "owner": {"email": "analytics@beanstalkcoffee.example", "name": "Analytics team"},
        "description": description,
        "label": None,
        "maturity": "high",
        "meta": {},
        "tags": tags,
        "config": {"enabled": True, "tags": tags, "meta": {}},
        "unrendered_config": {},
        "url": None,
        "depends_on": {"macros": [], "nodes": depends_on},
        "refs": [],
        "sources": [],
        "metrics": [],
        "created_at": 1716130800.0,
    }


def build_manifest() -> dict[str, Any]:
    nodes: dict[str, Any] = {}
    sources: dict[str, Any] = {}
    exposures: dict[str, Any] = {}

    # All source / model / seed unique_ids we'll allow as edge endpoints.
    valid_ids: set[str] = set()

    for src in SOURCES:
        s = build_source(*src)
        sources[s["unique_id"]] = s
        valid_ids.add(s["unique_id"])

    for seed in SEEDS:
        name, description, columns, tags = seed
        n = build_seed_node(name, description, columns, tags)
        nodes[n["unique_id"]] = n
        valid_ids.add(n["unique_id"])

    for m in MODELS:
        name, folder, materialized, description, depends_on, tags, columns = m
        n = build_model_node(name, folder, materialized, description, depends_on, tags, columns)
        nodes[n["unique_id"]] = n
        valid_ids.add(n["unique_id"])

    for ex in EXPOSURES:
        e = build_exposure(*ex)
        exposures[e["unique_id"]] = e
        valid_ids.add(e["unique_id"])

    # Validate every depends_on points to a real id.
    for uid, node in {**nodes, **exposures}.items():
        for parent in node.get("depends_on", {}).get("nodes", []):
            if parent not in valid_ids:
                raise SystemExit(f"Unknown dependency {parent!r} referenced by {uid}")

    # Build parent_map / child_map. dbt populates these for every unique_id.
    parent_map: dict[str, list[str]] = {uid: [] for uid in valid_ids}
    child_map: dict[str, list[str]] = {uid: [] for uid in valid_ids}

    for uid, node in {**nodes, **exposures}.items():
        parents = list(node.get("depends_on", {}).get("nodes", []))
        parent_map[uid] = parents
        for p in parents:
            child_map[p].append(uid)

    metadata = {
        "dbt_schema_version": "https://schemas.getdbt.com/dbt/manifest/v12.json",
        "dbt_version": DBT_VERSION,
        "generated_at": GENERATED_AT,
        "invocation_id": INVOCATION_ID,
        "env": {},
        "project_name": PACKAGE,
        "project_id": str(uuid.UUID("00000000-0000-4000-8000-000000000001")),
        "user_id": None,
        "send_anonymous_usage_stats": False,
        "adapter_type": ADAPTER,
    }

    return {
        "metadata": metadata,
        "nodes": nodes,
        "sources": sources,
        "macros": {},
        "docs": {},
        "exposures": exposures,
        "metrics": {},
        "groups": {},
        "selectors": {},
        "disabled": {},
        "parent_map": parent_map,
        "child_map": child_map,
        "group_map": {},
        "saved_queries": {},
        "semantic_models": {},
        "unit_tests": {},
    }


def iso(ts: dt.datetime) -> str:
    # dbt writes microsecond ISO timestamps with a trailing Z.
    return ts.replace(tzinfo=None).isoformat(timespec="microseconds") + "Z"


def build_run_results(manifest: dict[str, Any]) -> dict[str, Any]:
    rng = random.Random(0xC0FFEE)
    results: list[dict[str, Any]] = []

    # Walk nodes (models + seeds) in deterministic order; exposures last.
    cursor = RUN_STARTED_AT
    thread_count = 4
    thread_cursors = [RUN_STARTED_AT for _ in range(thread_count)]

    def append_result(unique_id: str, base_seconds: float, status: str, message: str | None) -> None:
        # ±12% deterministic jitter so sibling models don't share an identical
        # timing — keeps the build-time gradient visually varied.
        jitter = rng.uniform(-0.12, 0.12)
        duration = max(0.001, base_seconds * (1.0 + jitter))

        thread_idx = rng.randrange(thread_count)
        compile_start = thread_cursors[thread_idx]
        compile_end = compile_start + dt.timedelta(seconds=0.002 + rng.uniform(0, 0.004))
        execute_start = compile_end + dt.timedelta(microseconds=rng.randint(200, 1500))
        execute_end = execute_start + dt.timedelta(seconds=duration)
        thread_cursors[thread_idx] = execute_end + dt.timedelta(milliseconds=rng.randint(5, 60))

        results.append({
            "status": status,
            "timing": [
                {"name": "compile",
                    "started_at": iso(compile_start),
                    "completed_at": iso(compile_end)},
                {"name": "execute",
                    "started_at": iso(execute_start),
                    "completed_at": iso(execute_end)},
            ],
            "thread_id": f"Thread-{thread_idx + 1} (worker)",
            "execution_time": duration + 0.002,
            "adapter_response": {} if status == "no-op" else {
                "_message": "SELECT 1",
                "code": "SELECT",
                "rows_affected": rng.randint(100, 50000),
            },
            "message": message,
            "failures": None,
            "unique_id": unique_id,
            "compiled": status != "no-op",
            "compiled_code": None,
            "relation_name": None,
            "batch_results": None,
        })

    # Models + seeds with a known build time. Stable order: seeds first
    # (lookups loaded before anything that depends on them), then models in
    # depth-then-name order so the timing in the JSON tells a coherent story.
    depth: dict[str, int] = {}
    valid_ids = set(manifest["nodes"]) | set(manifest["sources"]) | set(manifest["exposures"])

    def compute_depth(uid: str, stack: set[str]) -> int:
        if uid in depth:
            return depth[uid]
        if uid in stack:
            return 0  # safety: not expected in a DAG
        stack.add(uid)
        parents = manifest["parent_map"].get(uid, [])
        d = 0 if not parents else 1 + max(compute_depth(p, stack) for p in parents if p in valid_ids)
        stack.remove(uid)
        depth[uid] = d
        return d

    for uid in list(manifest["nodes"].keys()) + list(manifest["exposures"].keys()):
        compute_depth(uid, set())

    buildable = []
    for uid, node in manifest["nodes"].items():
        if node["resource_type"] not in ("model", "seed"):
            continue
        if node["name"] in EPHEMERAL_MODELS:
            continue
        if node["name"] not in BUILD_TIMES:
            raise SystemExit(f"Missing BUILD_TIMES entry for {node['name']}")
        buildable.append((depth[uid], node["name"], uid))
    buildable.sort()

    for _, _, uid in buildable:
        node = manifest["nodes"][uid]
        append_result(uid, BUILD_TIMES[node["name"]], status="success", message="OK")

    # Exposures: no-op, fixed tiny execution time.
    for uid in manifest["exposures"]:
        append_result(uid, EXPOSURE_NOOP_SECONDS, status="no-op", message="NO-OP")

    total_elapsed = sum(r["execution_time"] for r in results) + 0.15  # small overhead

    metadata = {
        "dbt_schema_version": "https://schemas.getdbt.com/dbt/run-results/v6.json",
        "dbt_version": DBT_VERSION,
        "generated_at": GENERATED_AT,
        "invocation_id": INVOCATION_ID,
        "env": {},
    }

    return {
        "metadata": metadata,
        "results": results,
        "elapsed_time": round(total_elapsed, 3),
        "args": {
            "which": "build",
            "log_format": "default",
            "send_anonymous_usage_stats": False,
        },
    }


def main() -> None:
    target_dir = pathlib.Path(__file__).resolve().parent.parent / "fixtures" / "demo-coffee-shop" / "target"
    target_dir.mkdir(parents=True, exist_ok=True)

    manifest = build_manifest()
    manifest_path = target_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    run_results = build_run_results(manifest)
    run_results_path = target_dir / "run_results.json"
    run_results_path.write_text(json.dumps(run_results, indent=2) + "\n")

    model_count = sum(1 for n in manifest["nodes"].values() if n["resource_type"] == "model")
    seed_count = sum(1 for n in manifest["nodes"].values() if n["resource_type"] == "seed")
    source_count = len(manifest["sources"])
    exposure_count = len(manifest["exposures"])
    edge_count = sum(len(v) for v in manifest["parent_map"].values())
    success_count = sum(1 for r in run_results["results"] if r["status"] == "success")
    noop_count = sum(1 for r in run_results["results"] if r["status"] == "no-op")
    times = [r["execution_time"] for r in run_results["results"] if r["status"] == "success"]

    print(f"Wrote {manifest_path}")
    print(f"  models:    {model_count}")
    print(f"  seeds:     {seed_count}")
    print(f"  sources:   {source_count}")
    print(f"  exposures: {exposure_count}")
    print(f"  edges:     {edge_count}")
    print(f"Wrote {run_results_path}")
    print(f"  built:     {success_count} (omitting {len(EPHEMERAL_MODELS)} ephemeral)")
    print(f"  no-op:     {noop_count}")
    if times:
        print(f"  time:      min={min(times):.3f}s  median={sorted(times)[len(times)//2]:.2f}s  max={max(times):.2f}s")
    print(f"  total:     {run_results['elapsed_time']}s")


if __name__ == "__main__":
    main()
