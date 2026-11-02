-- ============================================================================
-- SCRIPT: 02_insert_sample_data.sql
-- COURSE: Database Development with PL/SQL (INSY 8311)
-- GROUP: Assignment IV - Advanced Oracle PL/SQL Programming
-- STUDENTS: MUSAFIRI Arnold (20252IMA134) & INGABIRE Kevin (27780)
-- SYSTEM: AUCA University Student Academic & Financial Management System
-- ============================================================================

SET SERVEROUTPUT ON;
PROMPT Inserting initial reference data into DEPARTMENTS...

INSERT INTO departments (dept_id, dept_code, dept_name, faculty_name) VALUES
(10, 'INSY', 'Information Systems', 'Faculty of Information Technology');
INSERT INTO departments (dept_id, dept_code, dept_name, faculty_name) VALUES
(20, 'COSC', 'Computer Science', 'Faculty of Information Technology');
INSERT INTO departments (dept_id, dept_code, dept_name, faculty_name) VALUES
(30, 'ACCT', 'Accounting & Finance', 'Faculty of Business Administration');
INSERT INTO departments (dept_id, dept_code, dept_name, faculty_name) VALUES
(40, 'NURS', 'Nursing Sciences', 'Faculty of Health Sciences');

PROMPT Inserting initial data into COURSES...

-- INSY Courses
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(101, 'INSY 8311', 'Database Development with PL/SQL', 3, 10, 60000.00, 30, 'ACTIVE');
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(102, 'INSY 8210', 'Enterprise Systems Architecture', 3, 10, 55000.00, 25, 'ACTIVE');
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(103, 'INSY 8105', 'Advanced Systems Analysis & Design', 4, 10, 50000.00, 35, 'ACTIVE');
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(104, 'INSY 8400', 'Cloud Infrastructure & DevOps', 3, 10, 65000.00, 2, 'ACTIVE'); -- small capacity for testing capacity limit!
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(105, 'INSY 8999', 'Legacy Mainframe Programming', 3, 10, 45000.00, 20, 'INACTIVE'); -- inactive course for testing

-- Computer Science Courses
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(201, 'COSC 7201', 'Data Structures & Algorithms', 4, 20, 55000.00, 40, 'ACTIVE');
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(202, 'COSC 7305', 'Artificial Intelligence & Machine Learning', 3, 20, 70000.00, 30, 'ACTIVE');

-- Business Courses
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, fee_per_credit, max_capacity, status) VALUES
(301, 'ACCT 6101', 'Financial Accounting Principles', 3, 30, 45000.00, 50, 'ACTIVE');

PROMPT Inserting initial data into STUDENTS...

-- Student 1: MUSAFIRI Arnold (Author 1)
INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1001, '20252IMA134', 'Arnold', 'MUSAFIRI', 'arnold.musafiri@auca.ac.rw', 10, TO_DATE('2024-09-01', 'YYYY-MM-DD'), 3.85, 0.00, 'GOOD_STANDING');

-- Student 2: INGABIRE Kevin (Author 2)
INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1002, '27780', 'Kevin', 'INGABIRE', 'kevin.ingabire@auca.ac.rw', 10, TO_DATE('2024-09-01', 'YYYY-MM-DD'), 3.75, 0.00, 'GOOD_STANDING');

-- Additional Students for testing scenarios
INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1003, '20252IMA100', 'Diane', 'UWASE', 'diane.uwase@auca.ac.rw', 10, TO_DATE('2024-09-01', 'YYYY-MM-DD'), 3.60, 50000.00, 'GOOD_STANDING');

INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1004, '20252IMA105', 'Patrick', 'MUGISHA', 'patrick.mugisha@auca.ac.rw', 10, TO_DATE('2025-01-15', 'YYYY-MM-DD'), 2.90, 120000.00, 'GOOD_STANDING');

INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1005, '20252IMA110', 'Aline', 'MUTONI', 'aline.mutoni@auca.ac.rw', 20, TO_DATE('2025-01-15', 'YYYY-MM-DD'), 3.40, 0.00, 'GOOD_STANDING');

INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1006, '20252IMA115', 'Jean Claude', 'NSHUTI', 'jc.nshuti@auca.ac.rw', 10, TO_DATE('2023-09-01', 'YYYY-MM-DD'), 1.80, 250000.00, 'PROBATION');

INSERT INTO students (student_id, student_reg_no, first_name, last_name, email, dept_id, enrollment_date, current_gpa, balance_due, academic_status) VALUES
(1007, '20252IMA120', 'Eric', 'BIZIMANA', 'eric.bizimana@auca.ac.rw', 30, TO_DATE('2023-09-01', 'YYYY-MM-DD'), 0.00, 400000.00, 'SUSPENDED'); -- For error testing

PROMPT Inserting initial data into ENROLLMENTS...

-- Completed Courses for Arnold (student 1001)
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5001, 1001, 102, 'Semester 1 2025/2026', '2025-2026', 36.00, 54.00, 90.00, 'A', 4.00, 'COMPLETED');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5002, 1001, 103, 'Semester 1 2025/2026', '2025-2026', 34.00, 51.00, 85.00, 'A-', 3.75, 'COMPLETED');

-- Completed Courses for Kevin (student 1002)
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5003, 1002, 102, 'Semester 1 2025/2026', '2025-2026', 35.00, 52.00, 87.00, 'A-', 3.75, 'COMPLETED');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5004, 1002, 103, 'Semester 1 2025/2026', '2025-2026', 33.00, 53.00, 86.00, 'A-', 3.75, 'COMPLETED');

-- Current Semester (Semester 1 2026/2027) enrollments awaiting grade processing (INSY 8311)
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5005, 1001, 101, 'Semester 1 2026/2027', '2026-2027', 38.00, 57.00, NULL, NULL, NULL, 'ENROLLED');

INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5006, 1002, 101, 'Semester 1 2026/2027', '2026-2027', 37.00, 55.00, NULL, NULL, NULL, 'ENROLLED');

INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5007, 1003, 101, 'Semester 1 2026/2027', '2026-2027', 32.00, 48.00, NULL, NULL, NULL, 'ENROLLED');

INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5008, 1004, 101, 'Semester 1 2026/2027', '2026-2027', 28.00, 42.00, NULL, NULL, NULL, 'ENROLLED');

INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5009, 1005, 101, 'Semester 1 2026/2027', '2026-2027', 35.00, 53.00, NULL, NULL, NULL, 'ENROLLED');

-- Course 104 (Cloud Infrastructure) pre-enrolled to test capacity limit (max_capacity = 2)
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5010, 1003, 104, 'Semester 1 2026/2027', '2026-2027', NULL, NULL, NULL, NULL, NULL, 'ENROLLED');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status) VALUES
(5011, 1004, 104, 'Semester 1 2026/2027', '2026-2027', NULL, NULL, NULL, NULL, NULL, 'ENROLLED');

PROMPT Inserting initial data into STUDENT_FINANCIAL_LOG...

INSERT INTO student_financial_log (txn_id, student_id, course_id, txn_type, amount, txn_date, description) VALUES
(1, 1001, 102, 'TUITION_CHARGE', 165000.00, TO_DATE('2025-09-02', 'YYYY-MM-DD'), 'Tuition charge: INSY 8210 (3 credits)');
INSERT INTO student_financial_log (txn_id, student_id, course_id, txn_type, amount, txn_date, description) VALUES
(2, 1001, 102, 'PAYMENT', 165000.00, TO_DATE('2025-09-05', 'YYYY-MM-DD'), 'Bank Payment slip #BK-88419');

INSERT INTO student_financial_log (txn_id, student_id, course_id, txn_type, amount, txn_date, description) VALUES
(3, 1002, 102, 'TUITION_CHARGE', 165000.00, TO_DATE('2025-09-02', 'YYYY-MM-DD'), 'Tuition charge: INSY 8210 (3 credits)');
INSERT INTO student_financial_log (txn_id, student_id, course_id, txn_type, amount, txn_date, description) VALUES
(4, 1002, 102, 'PAYMENT', 165000.00, TO_DATE('2025-09-05', 'YYYY-MM-DD'), 'Mobile Money Ref #MOMO-77201');

COMMIT;
PROMPT Sample data committed successfully.
