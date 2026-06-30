"""
Hands-On 6, Task 2 & 3 - CRUD via ORM, then fix N+1 with joinedload.
Run: python crud.py
"""
import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, joinedload
from models import Base, Department, Student, Course, Enrollment, Professor

# echo=True logs every SQL statement -> lets us literally count queries to detect N+1
DATABASE_URL = "postgresql+psycopg2://postgres:postgres@localhost:5432/college_db_orm"
engine = create_engine(DATABASE_URL, echo=False)
Session = sessionmaker(bind=engine)
session = Session()


def reset_data():
    """Clean slate so this script is re-runnable."""
    session.query(Enrollment).delete()
    session.query(Student).delete()
    session.query(Course).delete()
    session.query(Professor).delete()
    session.query(Department).delete()
    session.commit()


def task2_crud():
    # Step 81: INSERT 3 departments, 5 students
    depts = [
        Department(dept_name="Computer Science", head_of_dept="Dr. Ramesh Kumar", budget=850000),
        Department(dept_name="Electronics", head_of_dept="Dr. Priya Nair", budget=620000),
        Department(dept_name="Mechanical", head_of_dept="Dr. Suresh Iyer", budget=540000),
    ]
    session.add_all(depts)
    session.commit()

    students = [
        Student(first_name="Arjun", last_name="Mehta", email="arjun.mehta@college.edu",
                date_of_birth=datetime.date(2003, 4, 12), department_id=depts[0].department_id, enrollment_year=2022),
        Student(first_name="Priya", last_name="Suresh", email="priya.suresh@college.edu",
                date_of_birth=datetime.date(2003, 7, 25), department_id=depts[0].department_id, enrollment_year=2022),
        Student(first_name="Rohan", last_name="Verma", email="rohan.verma@college.edu",
                date_of_birth=datetime.date(2002, 11, 8), department_id=depts[1].department_id, enrollment_year=2021),
        Student(first_name="Sneha", last_name="Patel", email="sneha.patel@college.edu",
                date_of_birth=datetime.date(2004, 1, 30), department_id=depts[2].department_id, enrollment_year=2023),
        Student(first_name="Vikram", last_name="Das", email="vikram.das@college.edu",
                date_of_birth=datetime.date(2003, 9, 14), department_id=depts[0].department_id, enrollment_year=2022),
    ]
    session.add_all(students)
    session.commit()
    print(f"Step 81: inserted {len(depts)} departments, {len(students)} students")

    # Step 82: INSERT 3 courses, 4 enrollments
    courses = [
        Course(course_name="Data Structures & Algorithms", course_code="CS101", credits=4, department_id=depts[0].department_id),
        Course(course_name="Database Management Systems", course_code="CS102", credits=3, department_id=depts[0].department_id),
        Course(course_name="Circuit Theory", course_code="EC101", credits=3, department_id=depts[1].department_id),
    ]
    session.add_all(courses)
    session.commit()

    enrollments = [
        Enrollment(student_id=students[0].student_id, course_id=courses[0].course_id, enrollment_date=datetime.date(2022, 7, 1), grade="A"),
        Enrollment(student_id=students[1].student_id, course_id=courses[0].course_id, enrollment_date=datetime.date(2022, 7, 1), grade="B"),
        Enrollment(student_id=students[2].student_id, course_id=courses[2].course_id, enrollment_date=datetime.date(2021, 7, 1), grade="A"),
        Enrollment(student_id=students[4].student_id, course_id=courses[1].course_id, enrollment_date=datetime.date(2022, 7, 1), grade="B"),
    ]
    session.add_all(enrollments)
    session.commit()
    print(f"Step 82: inserted {len(courses)} courses, {len(enrollments)} enrollments")

    # Step 83: READ all students in Computer Science
    cs_students = (
        session.query(Student)
        .join(Department)
        .filter(Department.dept_name == "Computer Science")
        .all()
    )
    print(f"Step 83: {len(cs_students)} students in Computer Science: "
          f"{[s.first_name for s in cs_students]}")

    # Step 84: READ all enrollments + print student name & course name
    # (uses lazy-loaded relationships - this is the N+1 trap)
    print("\nStep 84: lazy-loaded enrollment read (watch query count in Task 3 below)")
    all_enrollments = session.query(Enrollment).all()
    for e in all_enrollments:
        _ = e.student.first_name  # triggers a separate SELECT per row (lazy load)
        _ = e.course.course_name  # triggers another separate SELECT per row

    # Step 85: UPDATE - find student by email, update enrollment_year
    student = session.query(Student).filter_by(email="sneha.patel@college.edu").first()
    student.enrollment_year = 2024
    session.commit()
    print(f"\nStep 85: updated {student.first_name}'s enrollment_year to {student.enrollment_year}")

    # Step 86: DELETE an enrollment
    enrollment_to_delete = session.query(Enrollment).first()
    eid = enrollment_to_delete.enrollment_id
    session.delete(enrollment_to_delete)
    session.commit()
    still_exists = session.query(Enrollment).filter_by(enrollment_id=eid).first()
    print(f"Step 86: deleted enrollment {eid}. Still exists? {still_exists is not None}")


def task3_fix_n_plus_1():
    """Step 87-90: count queries for lazy-load vs joinedload using an event listener."""
    from sqlalchemy import event

    query_count = {"n": 0}

    def count_queries(conn, cursor, statement, parameters, context, executemany):
        query_count["n"] += 1

    event.listen(engine, "before_cursor_execute", count_queries)

    # --- Lazy-load version (N+1) ---
    session.expire_all()
    query_count["n"] = 0
    enrollments = session.query(Enrollment).all()
    for e in enrollments:
        _ = e.student.first_name
        _ = e.course.course_name
    lazy_query_count = query_count["n"]
    print(f"\nStep 87: lazy-load version issued {lazy_query_count} SQL statements "
          f"for {len(enrollments)} enrollments (1 base query + 2 per row = N+1 pattern)")

    # --- joinedload version (fixed) ---
    session.expire_all()
    query_count["n"] = 0
    enrollments_eager = (
        session.query(Enrollment)
        .options(joinedload(Enrollment.student), joinedload(Enrollment.course))
        .all()
    )
    for e in enrollments_eager:
        _ = e.student.first_name
        _ = e.course.course_name
    eager_query_count = query_count["n"]
    print(f"Step 88-89: joinedload version issued {eager_query_count} SQL statement(s) "
          f"for the same {len(enrollments_eager)} enrollments")

    event.remove(engine, "before_cursor_execute", count_queries)

    print(f"\nStep 90: query count went from {lazy_query_count} (lazy/N+1) "
          f"to {eager_query_count} (joinedload) - "
          f"{lazy_query_count - eager_query_count} fewer round-trips for identical data.")


if __name__ == "__main__":
    Base.metadata.create_all(engine)  # ensure tables exist
    reset_data()
    task2_crud()
    task3_fix_n_plus_1()
    session.close()
