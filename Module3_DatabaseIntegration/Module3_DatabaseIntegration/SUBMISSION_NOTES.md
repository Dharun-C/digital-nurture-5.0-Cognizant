# Module 3 - Database Integration | Submission Notes

**Submitted by:** Dharun
**Scenario:** Student Course Registration System (college_db)

## What's in this folder

| File | Hands-On | Status |
|---|---|---|
| `hands_on_1.sql` | 1 - Schema Design, DDL, Normalisation | Tested live against PostgreSQL 16. All 5 tables, FKs, CHECK constraint, ALTER/RENAME/DROP verified with zero errors. |
| `hands_on_2.sql` | 2 - DML, Joins, Aggregations | Tested live. All query outputs match the exercise's expected outcomes exactly (10 students, correct JOIN/GROUP BY/HAVING results). |
| `hands_on_3.sql` | 3 - Subqueries, Views, Procedures, Transactions | Tested live. Transaction rollback on FK violation verified atomic; SAVEPOINT partial-rollback verified correct. |
| `hands_on_4.sql` | 4 - Indexes, EXPLAIN, N+1 (SQL part) | Tested live. Real `EXPLAIN` output captured and documented inline (not fabricated). |
| `n_plus_one_demo.py` | 4 - N+1 Problem (Python part) | Tested live. Confirmed: N+1 version = 13 queries, JOIN version = 1 query, identical data. |
| `hands_on_5_mongo.js` | 5 - MongoDB CRUD & Aggregation | **NOT executed** - no MongoDB server available in this build environment. Syntax is correct mongosh/Compass shell syntax; run it yourself in Compass's shell tab or `mongosh`, and skim it once before submitting to be sure you can explain each stage. |
| `orm/models.py`, `orm/crud.py` | 6 - SQLAlchemy ORM | Tested live. CRUD verified; N+1 fix verified via real query-count event listener: 7 queries -> 1 query with `joinedload`. |
| `orm/migrations/` | 7 - Alembic Migrations | Tested live. 3 revisions generated and applied (initial schema, is_active column, course_schedules table). Full downgrade-to-base and re-upgrade-to-head cycle verified. |
| `orm/ROLLBACK_NOTES.md` | 7 - Task 3 nuance | Documents a subtlety in how `alembic downgrade -1` behaves relative to migration order - worth skimming before any evaluator Q&A. |

## One honest gap

MongoDB (Hands-On 5) could not be executed in this sandbox since `mongodb.com`
isn't on the allowed network list here. Everything else was run against a
real PostgreSQL 16 instance and real Python/SQLAlchemy/Alembic, not guessed.
Run the Mongo file yourself before submitting - it should take ~10 minutes
in Compass, and the syntax has been double-checked against current MongoDB
documentation conventions.

## To push to GitHub right now

```bash
cd Module3_DatabaseIntegration
git init
git add .
git commit -m "Module 3: Database Integration - all 7 hands-on exercises"
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```
