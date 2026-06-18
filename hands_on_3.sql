-- HANDS-ON 3
-- Advanced SQL: Subqueries, Views & Transactions

-- 1. Students enrolled in more courses than average
SELECT student_id, COUNT(*) AS total_courses
FROM enrollments
GROUP BY student_id
HAVING COUNT(*) >
(
SELECT AVG(course_count)
FROM
(
SELECT COUNT(*) AS course_count
FROM enrollments
GROUP BY student_id
) avg_table
);

-- 2. Courses where all students received grade A
SELECT c.course_name
FROM courses c
WHERE NOT EXISTS
(
SELECT *
FROM enrollments e
WHERE e.course_id = c.course_id
AND e.grade <> 'A'
);

-- 3. Highest paid professor in each department
SELECT p.*
FROM professors p
WHERE salary =
(
SELECT MAX(salary)
FROM professors p2
WHERE p2.department_id = p.department_id
);

-- 4. Departments with average professor salary above 85000
SELECT department_id, AVG(salary) AS avg_salary
FROM professors
GROUP BY department_id
HAVING AVG(salary) > 85000;

-- 5. Create Student Summary View
CREATE VIEW vw_student_summary AS
SELECT
s.student_id,
s.first_name,
s.last_name,
d.department_name
FROM students s
JOIN departments d
ON s.department_id = d.department_id;

-- 6. View Data
SELECT * FROM vw_student_summary;

-- 7. Create Course Statistics View
CREATE VIEW vw_course_stats AS
SELECT
c.course_name,
COUNT(e.student_id) AS total_students
FROM courses c
LEFT JOIN enrollments e
ON c.course_id = e.course_id
GROUP BY c.course_id,c.course_name;

-- 8. View Course Statistics
SELECT * FROM vw_course_stats;

-- 9. Students with GPA greater than 3
SELECT *
FROM vw_student_summary
WHERE student_id IN
(
SELECT student_id
FROM enrollments
GROUP BY student_id
HAVING AVG(
CASE
WHEN grade='A' THEN 4
WHEN grade='B' THEN 3
WHEN grade='C' THEN 2
WHEN grade='D' THEN 1
ELSE 0
END
) > 3
);

-- 10. Transaction Example
START TRANSACTION;

INSERT INTO enrollments
(student_id,course_id,enrollment_date,grade)
VALUES
(1,3,CURDATE(),'A');

COMMIT;

-- 11. Rollback Example
START TRANSACTION;

INSERT INTO enrollments
(student_id,course_id,enrollment_date,grade)
VALUES
(2,3,CURDATE(),'B');

ROLLBACK;

-- 12. Savepoint Example
START TRANSACTION;

INSERT INTO enrollments
(student_id,course_id,enrollment_date,grade)
VALUES
(3,2,CURDATE(),'A');

SAVEPOINT sp1;

INSERT INTO enrollments
(student_id,course_id,enrollment_date,grade)
VALUES
(4,1,CURDATE(),'B');

ROLLBACK TO sp1;

COMMIT;

-- 13. Drop Views
DROP VIEW IF EXISTS vw_student_summary;
DROP VIEW IF EXISTS vw_course_stats;
