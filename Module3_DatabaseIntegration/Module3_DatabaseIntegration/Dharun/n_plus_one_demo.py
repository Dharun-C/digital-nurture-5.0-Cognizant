"""
Hands-On 4, Task 3 (Steps 56-59) - Identify and Fix the N+1 Problem
Connects to college_db with psycopg2, demonstrates the N+1 anti-pattern,
then fixes it with a single JOIN query, and times both approaches.
"""
import time
import psycopg2

DB_CONFIG = dict(
    host="localhost",
    dbname="college_db",
    user="postgres",
    password="postgres",
)


def n_plus_1_version():
    """BAD: 1 query to get all enrollments, then N more queries (one per row)."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    query_count = 0

    cur.execute("SELECT enrollment_id, student_id, course_id FROM enrollments;")
    query_count += 1
    enrollments = cur.fetchall()

    results = []
    for enrollment_id, student_id, course_id in enrollments:
        cur.execute("SELECT first_name, last_name FROM students WHERE student_id = %s;", (student_id,))
        query_count += 1
        first_name, last_name = cur.fetchone()
        results.append((enrollment_id, f"{first_name} {last_name}"))

    cur.close()
    conn.close()
    print(f"[N+1 version]   {query_count} queries executed")
    return results, query_count


def joined_version():
    """GOOD: 1 query total - JOIN fetches enrollment + student name together."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    query_count = 0

    cur.execute("""
        SELECT e.enrollment_id, s.first_name, s.last_name
        FROM enrollments e
        JOIN students s ON s.student_id = e.student_id;
    """)
    query_count += 1
    rows = cur.fetchall()
    results = [(eid, f"{fn} {ln}") for eid, fn, ln in rows]

    cur.close()
    conn.close()
    print(f"[JOIN version]  {query_count} query executed")
    return results, query_count


if __name__ == "__main__":
    start1 = time.perf_counter()
    res1, count1 = n_plus_1_version()
    elapsed1 = time.perf_counter() - start1

    start2 = time.perf_counter()
    res2, count2 = joined_version()
    elapsed2 = time.perf_counter() - start2

    print(f"\nN+1 version:  {count1} queries, {elapsed1*1000:.2f} ms")
    print(f"JOIN version: {count2} query,  {elapsed2*1000:.2f} ms")
    print(f"Round-trip reduction: {count1 - count2} fewer queries "
          f"({((count1-count2)/count1)*100:.0f}% reduction)")

    assert sorted(res1) == sorted(res2), "Mismatch: both versions must return identical data!"
    print("\nData verified identical between both approaches.")

    # Step 59: in a real app with 10,000 enrollments, the N+1 version would issue
    # 1 (initial query) + 10,000 (one per row) = 10,001 queries total,
    # versus a flat 1 query for the JOIN/eager-loading version.
    n = 10_000
    print(f"\nAt {n:,} enrollments: N+1 version => {n + 1:,} queries | JOIN version => 1 query")
