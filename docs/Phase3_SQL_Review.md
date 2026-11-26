# Phase 3 SQL review

## Source reviewed

- `docs/Dì Mười_Phase1.pdf` (sample data and business rules)
- Project Phase 2 schema files in `docs/`

## Assessment

The team member's script is a solid Phase 3 base. It contains 15 relational tables, primary and foreign keys, checks, indexes, three triggers, four procedures, two functions, a current-status view, sample seed rows, and nine analytical queries. The normalized tables `CUSTOMER_ADDRESS`, `ORDER_NOTE`, and `ORDER_ITEM_CUSTOMIZATION` represent multivalued attributes from Phase 1. Composite foreign keys also protect the order-to-restaurant/menu-item path.

## Changes made in the integrated script

- Isolated the script in `food_delivery_phase3_workbench`; it no longer drops the general `mini_doordash` database.
- Set `utf8mb4` so Vietnamese seed values are preserved.
- Declared the agreed order-status values directly in `ORDER_STATUS_HISTORY` rather than creating and then replacing the check constraint.
- Changed `UpdateOrderStatus` to lock the base `ORDERS` row before reading the derived status view, and added an explicit missing-order error.
- Renumbered the existing nine queries and added queries for restaurant revenue, delivery retries, subtotal reconciliation, and current order status.
- Corrected the high-price variant query to count only successfully delivered quantities.

## Data alignment note

The teammate's seed data maps the Phase 1 identifiers to integers and retains its customer, restaurant, menu, delivery, review, and loyalty examples. However, some values are normalized or altered and should not be described as a byte-for-byte transcription of the Phase 1 report. For example, the Phase 1 report shows `ORD001` with `VAR005` at 58,000 and `VAR018` at 350,000 × 2, totaling 758,000; the teammate script instead uses `VAR005` at 58,000 and `VAR015` at 320,000 × 2, totaling 698,000. In the Phase 1 variant table, `VAR018` belongs to a different restaurant than `VAR005`, so the raw sample also conflicts with the Phase 1 rule that each order belongs to one restaurant. Similar cross-restaurant variant references appear in other Phase 1 order-item rows.

The integrated file retains the teammate's internally consistent, constraint-compatible order items and totals rather than silently inserting Phase 1 rows that violate the restaurant ownership constraint. The report should identify this as a sample-data normalization decision. To make the seed set exactly match the Phase 1 report, the project team must first correct those conflicting source rows or explicitly relax the single-restaurant-per-order rule.

The sample also models order 15 as delivered and later returned (`Delivery Failed` in the normalized status vocabulary). The review trigger accepts a review when a delivered event exists in the order's history, which permits the Phase 1 review for that order. This implements historical delivery eligibility; the team should keep that rule explicit.

## Remaining project verification

The script was reviewed statically against its DDL and seed relationships. It was not executed against a MySQL server in this pass. Confirm the team's preferred resolution for the Phase 1 mixed-restaurant sample rows before claiming exact source-data fidelity in the Phase 3 report.


## Use of existing situation data

The integrated script now queries the existing sample at the right level:

- Query 4 looks for customers with at least two currently delivered orders and at least one of those orders without a review. This uses the existing order/review rows; it does not claim that those customers have never written any review.
- Query 11 lists orders whose current status is `Delivery Failed` and whose assignment history contains a failed or rejected attempt. It surfaces the recorded failure cases for follow-up. It does not fabricate a subsequent reassignment event; the seed data contains no such recorded event.

If the team needs to show an actual reassignment chain, add it only from a factual assignment record (driver and timestamps) or report it as a documented sample extension. Do not present an invented event as historical data.
