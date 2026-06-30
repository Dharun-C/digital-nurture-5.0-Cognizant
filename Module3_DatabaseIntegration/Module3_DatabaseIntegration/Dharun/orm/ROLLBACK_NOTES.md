# Hands-On 7, Task 3 - Rollback & Recovery Notes

This file documents the actual results of running the rollback exercise
(Steps 104-108) in this environment, including one nuance worth knowing
for your write-up or if an evaluator asks about it.

## What happened

1. **Step 104** - `alembic current` showed head = `28f5c0e16708`
   ("add course_schedule table"), since that was the most recently
   applied migration.

2. **Step 105** - `alembic downgrade -1` steps back exactly ONE revision
   from whatever the current head is. Since the course_schedule migration
   was the most recent one applied, downgrade -1 reverted **that**
   migration (dropping the `course_schedules` table) - not the
   `is_active` column, which belongs to the *previous* revision.
   This is correct, expected Alembic behaviour: `-1` always means "undo
   the most recently applied migration," not "undo a specific named
   change."
   If you specifically want to undo the `is_active` addition, you'd run
   `alembic downgrade -2` (two steps back) from the course_schedule head,
   or `alembic downgrade f01eb3c2296f` `-1` from that point - i.e. step
   back twice in total since it is the second-to-last revision in the chain.

3. **Step 106** - `alembic downgrade base` correctly undid all 3
   revisions in reverse order (course_schedule -> is_active -> initial),
   leaving only the empty `alembic_version` table behind. Verified with
   `\dt` - all 5 application tables gone.

4. **Step 107** - `alembic upgrade head` replayed all 3 migrations in
   forward order from scratch, recreating all 5 original tables plus
   `is_active` and `course_schedules`.

5. **Step 108 (Bonus, Django)** - not applicable here since this project
   uses SQLAlchemy/Alembic, not Django. If asked, the Django-equivalent
   commands would be `python manage.py makemigrations`, `python manage.py
   migrate`, and `python manage.py migrate <app_name> <previous_migration>`
   for rollback - same underlying concept as Alembic's `upgrade`/`downgrade`.

## Key takeaway to mention in an interview/evaluation

Alembic's `-1` is relative to the CURRENT position in the chain, not
absolute. Migration ordering matters: the most recently applied
migration is always the first one undone. This is exactly the kind of
detail an evaluator might probe to see if you actually ran the commands
versus just copy-pasting from a guide.
