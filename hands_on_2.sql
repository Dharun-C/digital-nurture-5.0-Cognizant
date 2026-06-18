-- Hands-On 2 : Basic Queries

-- 1. Display all students
SELECT * FROM students;

-- 2. Display first name, last name and email
SELECT first_name,last_name,email
FROM students;

-- 3. Students from Computer Science Department (department_id = 1)
SELECT *
FROM students
WHERE department_id = 1;

-- 4. Courses with credits greater than or equal to 4
SELECT *
FROM courses
WHERE credits >= 4;

-- 5. Count students in each department
SELECT department_id, COUNT(*) AS student_count
FROM students
GROUP BY department_id;

-- 6. Average professor salary
SELECT AVG(salary) AS average_salary
FROM professors;

-- 7. Student and Department Details
SELECT s.first_name, s.last_name, d.department_name
FROM students s
INNER JOIN departments d
ON s.department_id = d.department_id;

-- 8. Student and Course Details
SELECT s.first_name, s.last_name, c.course_name
FROM students s
INNER JOIN enrollments e
ON s.student_id = e.student_id
INNER JOIN courses c
ON e.course_id = c.course_id;

-- 9. Number of students enrolled in each course
SELECT c.course_name, COUNT(e.student_id) AS enrolled_students
FROM courses c
LEFT JOIN enrollments e
ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name;

-- 10. Number of students in each department
SELECT d.department_name, COUNT(s.student_id) AS total_students
FROM departments d
LEFT JOIN students s
ON d.department_id = s.department_id
GROUP BY d.department_id, d.department_name;

-- 11. Professor and Department Details
SELECT p.prof_name, d.department_name
FROM professors p
INNER JOIN departments d
ON p.department_id = d.department_id;

-- 12. Students with Grade A
SELECT s.first_name, s.last_name, c.course_name, e.grade
FROM students s
INNER JOIN enrollments e
ON s.student_id = e.student_id
INNER JOIN courses c
ON e.course_id = c.course_id
WHERE e.grade = 'A';

-- 13. Average Salary by Department
SELECT d.department_name, AVG(p.salary) AS average_salary
FROM departments d
INNER JOIN professors p
ON d.department_id = p.department_id
GROUP BY d.department_id, d.department_name;

-- 14. Courses ordered by enrollment count
SELECT c.course_name, COUNT(e.student_id) AS enrolled_students
FROM courses c
LEFT JOIN enrollments e
ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name
ORDER BY enrolled_students DESC;

-- 15. Student, Department and Course Details
SELECT s.first_name, s.last_name, d.department_name, c.course_name
FROM students s
INNER JOIN departments d
ON s.department_id = d.department_id
INNER JOIN enrollments e
ON s.student_id = e.student_id
INNER JOIN courses c
ON e.course_id = c.course_id;

-- 16. Number of Courses in Each Department
SELECT d.department_name, COUNT(c.course_id) AS total_courses
FROM departments d
LEFT JOIN courses c
ON d.department_id = c.department_id
GROUP BY d.department_id, d.department_name;

-- 17. Number of Courses per Student
SELECT s.first_name, s.last_name, COUNT(e.course_id) AS total_courses
FROM students s
LEFT JOIN enrollments e
ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name;