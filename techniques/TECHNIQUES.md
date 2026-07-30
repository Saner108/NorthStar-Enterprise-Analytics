# Techniques & Methods — Overview

This pilot is deliberately small in scope but built with the same techniques a real
analytics engineering team would use. Each technique below is documented with three
things: **what** it is, **why** I chose it over the obvious alternative, and **what it
looks like** in the actual build (real SQL and real rows from the seed-42 dataset).

The theme throughout is **defensible over impressive**: every decision is one I can
explain and justify in an interview, and I've noted the alternative I rejected and why.

## Index

1. [Dimensional (star-schema) modeling](docs/01-dimensional-modeling.md)
2. [Two fact tables at different grains](docs/02-two-fact-grains.md)
3. [Daily snapshot grain](docs/03-snapshot-grain.md)
4. [Slowly Changing Dimension (Type 2)](docs/04-scd-type-2.md)
5. [Business-rule separation](docs/05-business-rule-separation.md)
6. [Pooled-inventory root-cause classification](docs/06-pooled-classification.md)
7. [Deterministic synthetic data generation](docs/07-synthetic-data-generation.md)
8. [Known-answer testing & automated validation](docs/08-validation-testing.md)
9. [Reporting / semantic view layer](docs/09-reporting-views.md)
10. [Audience-driven dashboard hierarchy](docs/10-dashboard-hierarchy.md)
