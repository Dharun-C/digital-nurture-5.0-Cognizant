-- ============================================================
-- HANDS-ON 1 [Beginner] - Schema Design & Core SQL
-- DDL and Normalisation | Database: college_db (PostgreSQL)
-- ============================================================

-- ============================================================
-- TASK 1: Create the Database and Tables
-- ============================================================

-- departments must be created first since other tables reference it
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    hod_name VARCHAR(100),
    budget DECIMAL(12,2)
);

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth DATE,
    department_id INT REFERENCES departments(department_id),
    enrollment_year INT
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(150) NOT NULL,
    course_code VARCHAR(20) UNIQUE,
    credits INT,
    department_id INT REFERENCES departments(department_id)
);

CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    enrollment_date DATE,
    grade CHAR(2)
);

CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    prof_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department_id INT REFERENCES departments(department_id),
    salary DECIMAL(10,2)
);

-- Expected Outcome check: \d students  (run manually to inspect constraints)


-- ============================================================
-- TASK 2: Verify Normalisation (1NF, 2NF, 3NF)
-- ============================================================

-- 1NF ANALYSIS:
-- Every column in every table holds a single atomic value (e.g. first_name,
-- email, salary are all scalar). A 1NF VIOLATION would occur if we stored
-- multiple phone numbers in one column, e.g. phone_numbers = '9876543210,9123456780'.
-- That repeating group breaks atomicity. Our schema has no such columns, so 1NF holds.

-- 2NF ANALYSIS:
-- 2NF requires every non-key column to depend on the WHOLE primary key, not part of it.
-- Most of our tables use a single-column surrogate key (student_id, course_id, etc.),
-- so 2NF is automatically satisfied for them.
-- The enrollments table is the interesting case: its composite CANDIDATE key is
-- (student_id, course_id) — together they should uniquely identify one enrollment.
-- enrollment_date and grade both depend on the combination of student_id AND course_id
-- (a grade is meaningless without knowing both which student and which course),
-- not on either column alone. Hence 2NF holds for enrollments.

-- 3NF ANALYSIS:
-- 3NF requires no transitive dependencies (non-key column depending on another
-- non-key column, rather than directly on the primary key).
-- Question: would storing dept_name directly in the students table violate 3NF?
-- YES — because dept_name depends on department_id, and department_id depends on
-- student_id. So dept_name would depend TRANSITIVELY on student_id (student_id ->
-- department_id -> dept_name), not directly. That is exactly why we instead store
-- only the department_id foreign key in students, and look up dept_name via JOIN.
-- Our actual schema avoids this by keeping department_id as a pure FK, so 3NF holds.


-- ============================================================
-- TASK 3: Alter and Extend the Schema
-- ============================================================

-- Step 10: add phone_number to students
ALTER TABLE students ADD COLUMN phone_number VARCHAR(15);

-- Step 11: add max_seats to courses
ALTER TABLE courses ADD COLUMN max_seats INT DEFAULT 60;

-- Step 12: CHECK constraint on enrollments.grade
ALTER TABLE enrollments
    ADD CONSTRAINT chk_grade CHECK (grade IN ('A','B','C','D','F') OR grade IS NULL);

-- Step 13: rename hod_name -> head_of_dept (PostgreSQL syntax)
ALTER TABLE departments RENAME COLUMN hod_name TO head_of_dept;

-- Step 14: drop phone_number (simulate rollback)
ALTER TABLE students DROP COLUMN phone_number;

-- Verify changes (PostgreSQL information_schema check)
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'students';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'courses';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'departments';
