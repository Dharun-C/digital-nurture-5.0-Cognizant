-- ============================================================
-- HANDS-ON 4 [Intermediate] - Query Optimisation
-- Indexes, EXPLAIN & the N+1 Problem | Database: college_db (PostgreSQL)
-- ============================================================

-- ============================================================
-- TASK 1: Baseline Performance - No Indexes
-- ============================================================

-- Step 48: EXPLAIN on the join query (baseline, before indexes)
EXPLAIN
SELECT s.first_name, s.last_name, c.course_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;

/*
BASELINE EXPLAIN OUTPUT (actual output captured in this environment):

  Nested Loop  (cost=12.16..42.16 rows=9 width=554)
    ->  Hash Join  (cost=12.01..40.40 rows=9 width=240)
          Hash Cond: (e.student_id = s.student_id)
          ->  Seq Scan on enrollments e  (cost=0.00..24.50 rows=1450 width=8)
          ->  Hash  (cost=12.00..12.00 rows=1 width=240)
                ->  Seq Scan on students s  (cost=0.00..12.00 rows=1 width=240)
                      Filter: (enrollment_year = 2022)
    ->  Index Scan using courses_pkey on courses c  (cost=0.14..0.20 rows=1 width=322)
          Index Cond: (course_id = e.course_id)

OBSERVATION (Step 49): students and enrollments both show "Seq Scan" -
there is no index yet on enrollment_year, so PostgreSQL must read every
row of students to apply the Filter, and every row of enrollments to
find matches. courses already gets an Index Scan here because course_id
is its PRIMARY KEY (PKs are automatically indexed).

OBSERVATION (Step 50): the planner's row-count estimate for enrollments
(rows=1450) is inflated relative to the real ~12 rows, because
PostgreSQL's autovacuum statistics had not yet run against this
freshly-loaded table - on a real production table that has been
ANALYZE'd, this estimate would track the true row count, and the
Seq Scan cost would scale linearly with table size: at 100,000 rows,
that same full-table read becomes the dominant cost in the plan.
*/


-- ============================================================
-- TASK 2: Add Indexes and Compare Plans
-- ============================================================

-- Step 51: B-Tree index on students.enrollment_year
CREATE INDEX idx_students_enrollment_year ON students(enrollment_year);

-- Step 52: composite UNIQUE index on enrollments(student_id, course_id)
-- (also enforces no duplicate enrollments going forward)
CREATE UNIQUE INDEX idx_enrollments_student_course ON enrollments(student_id, course_id);

-- Step 53: index on courses.course_code
CREATE INDEX idx_courses_course_code ON courses(course_code);

-- Step 54: re-run EXPLAIN and compare
EXPLAIN
SELECT s.first_name, s.last_name, c.course_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;

/*
POST-INDEX OBSERVATION (Step 54):
On a dataset this small, PostgreSQL's planner will often still choose a
Seq Scan over students/courses/enrollments, because the table fits in a
single page and a Seq Scan is genuinely cheaper than the overhead of an
Index Scan for so few rows - this is expected planner behaviour, not a
bug. The idx_students_enrollment_year index DOES get used once the
students table grows large enough (thousands+ rows) that filtering via
the index beats reading the whole table; you can prove the index is
live and valid by running:
    SELECT indexname FROM pg_indexes WHERE tablename = 'students';
which confirms idx_students_enrollment_year exists, and:
    SET enable_seqscan = off;
    EXPLAIN SELECT * FROM students WHERE enrollment_year = 2022;
which forces the planner to pick the Index Scan path even on small data,
visibly switching "Seq Scan on students" to "Index Scan using
idx_students_enrollment_year on students" in the plan.
*/

SET enable_seqscan = off;
EXPLAIN SELECT * FROM students WHERE enrollment_year = 2022;
SET enable_seqscan = on; -- restore default planner behaviour

-- Step 55: partial index for unevaluated enrollments
CREATE INDEX idx_enrollments_no_grade ON enrollments(student_id) WHERE grade IS NULL;
-- Note: on this dataset all NULL-grade rows were deleted in Hands-On 2,
-- so this partial index currently indexes 0 rows - but it is created
-- correctly and will activate automatically as soon as any enrollment
-- with a NULL grade exists.


-- ============================================================
-- TASK 3: Identify and Fix the N+1 Problem -> see n_plus_one_demo.py
-- (Python script, run separately - see file in repo root)
-- ============================================================
-- Step 56-59 require Python (psycopg2) execution + timing, which cannot
-- be done in pure SQL. See n_plus_one_demo.py.
