-- ============================================================
-- HANDS-ON 3 [Intermediate] - Advanced SQL
-- Subqueries, Views & Transactions | Database: college_db (PostgreSQL)
-- ============================================================

-- ============================================================
-- TASK 1: Subqueries
-- ============================================================

-- Step 35: students enrolled in more courses than the average enrollments per student
-- (non-correlated subquery calculates the average)
SELECT student_id, COUNT(*) AS course_count
FROM enrollments
GROUP BY student_id
HAVING COUNT(*) > (
    SELECT AVG(cnt) FROM (
        SELECT COUNT(*) AS cnt FROM enrollments GROUP BY student_id
    ) AS sub
);

-- Step 36: courses where ALL enrolled students got grade 'A' (correlated subquery / NOT EXISTS)
SELECT c.course_name
FROM courses c
WHERE NOT EXISTS (
    SELECT 1 FROM enrollments e
    WHERE e.course_id = c.course_id AND (e.grade != 'A' OR e.grade IS NULL)
)
AND EXISTS (
    SELECT 1 FROM enrollments e2 WHERE e2.course_id = c.course_id
);

-- Step 37: professor with highest salary in each department (correlated subquery)
SELECT p.prof_name, p.department_id, p.salary
FROM professors p
WHERE p.salary = (
    SELECT MAX(p2.salary) FROM professors p2 WHERE p2.department_id = p.department_id
);

-- Step 38: derived table - per-department avg salary, filter > 85000
SELECT dept_avg.department_id, dept_avg.avg_salary
FROM (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM professors
    GROUP BY department_id
) AS dept_avg
WHERE dept_avg.avg_salary > 85000;


-- ============================================================
-- TASK 2: Creating and Using Views
-- ============================================================

-- Step 39: vw_student_enrollment_summary
CREATE OR REPLACE VIEW vw_student_enrollment_summary AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    d.dept_name,
    COUNT(e.enrollment_id) AS courses_enrolled,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0
        END
    ), 2) AS gpa
FROM students s
JOIN departments d ON s.department_id = d.department_id
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name, d.dept_name;

-- Step 40: vw_course_stats
CREATE OR REPLACE VIEW vw_course_stats AS
SELECT
    c.course_name,
    c.course_code,
    COUNT(e.enrollment_id) AS total_enrollments,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0
        END
    ), 2) AS avg_gpa
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.course_code;

-- Step 41: students with GPA above 3.0
SELECT * FROM vw_student_enrollment_summary WHERE gpa > 3.0;

-- Step 42: attempt UPDATE through the multi-table view
-- UPDATE vw_student_enrollment_summary SET gpa = 4.0 WHERE student_id = 1;
-- RESULT: ERROR - PostgreSQL rejects this because the view is built from a JOIN
-- across multiple tables (students, departments, enrollments) plus an aggregate
-- (COUNT/AVG). Multi-table / aggregated views are not "simply updatable" because
-- the database cannot unambiguously map a change in the view back to exactly
-- one row in exactly one base table. Only views that are a simple SELECT over
-- a single table, with no aggregation/DISTINCT/GROUP BY/JOIN, are updatable.

-- Step 43: drop and recreate as single-table view WITH CHECK OPTION
DROP VIEW IF EXISTS vw_student_enrollment_summary;
DROP VIEW IF EXISTS vw_course_stats;

-- Single-table subset view: students enrolled in 2022 only, with CHECK OPTION
CREATE OR REPLACE VIEW vw_students_2022 AS
SELECT student_id, first_name, last_name, email, enrollment_year
FROM students
WHERE enrollment_year = 2022
WITH CHECK OPTION;
-- WITH CHECK OPTION means: any INSERT/UPDATE through this view that would
-- produce a row with enrollment_year != 2022 (i.e. invisible through the
-- view's own WHERE clause) is rejected by PostgreSQL.

-- Recreate the two original views (needed for later exercises)
CREATE OR REPLACE VIEW vw_student_enrollment_summary AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    d.dept_name,
    COUNT(e.enrollment_id) AS courses_enrolled,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0
        END
    ), 2) AS gpa
FROM students s
JOIN departments d ON s.department_id = d.department_id
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name, d.dept_name;

CREATE OR REPLACE VIEW vw_course_stats AS
SELECT
    c.course_name,
    c.course_code,
    COUNT(e.enrollment_id) AS total_enrollments,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0
        END
    ), 2) AS avg_gpa
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.course_code;

SELECT * FROM vw_course_stats; -- expect 5 rows, one per course


-- ============================================================
-- TASK 3: Stored Procedures (PostgreSQL Functions) and Transactions
-- ============================================================

-- Step 44: fn_enroll_student - checks for duplicate enrollment before inserting
CREATE OR REPLACE FUNCTION fn_enroll_student(
    p_student_id INT,
    p_course_id INT,
    p_enrollment_date DATE
) RETURNS VOID AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = p_student_id AND course_id = p_course_id
    ) THEN
        RAISE EXCEPTION 'Duplicate enrollment: student % is already enrolled in course %',
            p_student_id, p_course_id;
    END IF;

    INSERT INTO enrollments (student_id, course_id, enrollment_date)
    VALUES (p_student_id, p_course_id, p_enrollment_date);
END;
$$ LANGUAGE plpgsql;

-- Test: this should succeed (student 3 not yet enrolled in course 2)
SELECT fn_enroll_student(3, 2, '2024-01-10');
-- Test: this should raise the duplicate-enrollment error (student 1 already in course 1)
-- SELECT fn_enroll_student(1, 1, '2024-01-10');

-- Step 45: department_transfer_log table + sp_transfer_student function
CREATE TABLE IF NOT EXISTS department_transfer_log (
    log_id SERIAL PRIMARY KEY,
    student_id INT,
    old_department_id INT,
    new_department_id INT,
    transfer_date TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION sp_transfer_student(
    p_student_id INT,
    p_new_department_id INT
) RETURNS VOID AS $$
DECLARE
    v_old_dept INT;
BEGIN
    SELECT department_id INTO v_old_dept FROM students WHERE student_id = p_student_id;

    UPDATE students SET department_id = p_new_department_id WHERE student_id = p_student_id;

    INSERT INTO department_transfer_log (student_id, old_department_id, new_department_id)
    VALUES (p_student_id, v_old_dept, p_new_department_id);
END;
$$ LANGUAGE plpgsql;

-- Test transfer (valid)
SELECT sp_transfer_student(2, 3);

-- Step 46: test with an invalid FK to confirm rollback behaviour
-- Wrapping manually in a transaction block to demonstrate atomic rollback:
BEGIN;
    UPDATE students SET department_id = 999 WHERE student_id = 4; -- 999 doesn't exist
    INSERT INTO department_transfer_log (student_id, old_department_id, new_department_id)
    VALUES (4, 3, 999);
ROLLBACK;
-- Because department_id has an FK constraint, the UPDATE to 999 fails immediately,
-- which aborts the whole transaction block - the log INSERT never happens either,
-- and student_id=4's department_id remains unchanged. This proves atomicity:
-- either both statements succeed, or neither does.

-- Step 47: SAVEPOINT test
BEGIN;
    INSERT INTO enrollments (student_id, course_id, enrollment_date, grade)
    VALUES (6, 2, '2024-02-01', 'A');           -- record A: will be kept

    SAVEPOINT after_first_insert;

    INSERT INTO enrollments (student_id, course_id, enrollment_date, grade)
    VALUES (6, 999, '2024-02-01', 'A');          -- record B: invalid course_id -> fails

ROLLBACK TO SAVEPOINT after_first_insert;
COMMIT;
-- Verify: only the first insert (student 6, course 2) should be present
SELECT * FROM enrollments WHERE student_id = 6 AND course_id IN (2, 999);
