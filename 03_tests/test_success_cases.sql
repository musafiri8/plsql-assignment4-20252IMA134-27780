-- ============================================================================
-- SCRIPT: test_success_cases.sql
-- COURSE: Database Development with PL/SQL (INSY 8311)
-- GROUP: Assignment IV - Advanced Oracle PL/SQL Programming
-- STUDENTS: MUSAFIRI Arnold (20252IMA134) & INGABIRE Kevin (27780)
-- DESCRIPTION: Comprehensive suite of successful test executions demonstrating
--              Records, Collections, Explicit/Implicit Cursors, Bulk Processing,
--              Stored Procedures, and Functions.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
COL student_reg_no FORMAT A15;
COL first_name FORMAT A12;
COL last_name FORMAT A12;
COL course_code FORMAT A12;
COL letter_grade FORMAT A5;
COL current_gpa FORMAT 9.99;
COL balance_due FORMAT 999,999,990.00;

PROMPT ============================================================================
PROMPT TEST 1: Register Student 1001 (Arnold MUSAFIRI) for Course 201 (COSC 7201)
PROMPT Demonstrates: sp_register_student_course, User-Defined Record, %ROWTYPE, Implicit Cursors
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1001,
        p_course_id       => 201,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_status_msg);
    DBMS_OUTPUT.PUT_LINE('Generated Enrollment ID: ' || v_enroll_id || ' | Tuition: RWF ' || v_tuition);
END;
/

PROMPT ============================================================================
PROMPT TEST 2: Register Student 1002 (Kevin INGABIRE) for Course 201 (COSC 7201)
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1002,
        p_course_id       => 201,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_status_msg);
    DBMS_OUTPUT.PUT_LINE('Generated Enrollment ID: ' || v_enroll_id || ' | Tuition: RWF ' || v_tuition);
END;
/

PROMPT ============================================================================
PROMPT TEST 3: Bulk Process Grades for Course 101 (INSY 8311)
PROMPT Demonstrates: sp_bulk_process_grades, BULK COLLECT, FORALL SAVE EXCEPTIONS,
PROMPT               Nested Tables, Associative Arrays, VARRAY, Audit Trail Logging
PROMPT ============================================================================

DECLARE
    v_processed   NUMBER;
    v_errors      NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_bulk_process_grades(
        p_course_id       => 101,
        p_semester        => 'Semester 1 2026/2027',
        p_processed_count => v_processed,
        p_error_count     => v_errors,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('Bulk Operation Status: ' || v_status_msg);
    DBMS_OUTPUT.PUT_LINE('Total Processed: ' || v_processed || ' | Total Errors: ' || v_errors);
END;
/

PROMPT Verifying Bulk Processed Enrollments:
SELECT enrollment_id, student_id, course_id, midterm_score, final_score, total_score, letter_grade, grade_point, enrollment_status
FROM enrollments
WHERE course_id = 101;

PROMPT Verifying Grade Audit Log Entries:
SELECT audit_id, enrollment_id, new_total_score, new_letter_grade, changed_by, change_date, remarks
FROM grade_audit_log;

PROMPT ============================================================================
PROMPT TEST 4: Calculate Cumulative GPA using fn_calculate_gpa
PROMPT Demonstrates: fn_calculate_gpa, Explicit Cursor, Calling from SQL & PL/SQL
PROMPT ============================================================================

PROMPT SQL Query Call:
SELECT s.student_id,
       s.student_reg_no,
       s.first_name || ' ' || s.last_name AS student_name,
       fn_calculate_gpa(s.student_id) AS computed_gpa,
       s.current_gpa AS stored_gpa
FROM students s
WHERE s.student_id IN (1001, 1002, 1003);

PROMPT PL/SQL Anonymous Block Call:
DECLARE
    v_arnold_gpa NUMBER(3,2);
    v_kevin_gpa  NUMBER(3,2);
BEGIN
    v_arnold_gpa := fn_calculate_gpa(1001);
    v_kevin_gpa  := fn_calculate_gpa(1002);
    DBMS_OUTPUT.PUT_LINE('Calculated GPA for Arnold MUSAFIRI (1001): ' || TO_CHAR(v_arnold_gpa, '0.99'));
    DBMS_OUTPUT.PUT_LINE('Calculated GPA for Kevin INGABIRE  (1002): ' || TO_CHAR(v_kevin_gpa, '0.99'));
END;
/

PROMPT ============================================================================
PROMPT TEST 5: Test Letter Grade Determination Function (fn_determine_letter_grade)
PROMPT Demonstrates: fn_determine_letter_grade, Associative Array Lookup
PROMPT ============================================================================

SELECT 95 AS test_score, fn_determine_letter_grade(95) AS grade FROM DUAL
UNION ALL
SELECT 86 AS test_score, fn_determine_letter_grade(86) AS grade FROM DUAL
UNION ALL
SELECT 78 AS test_score, fn_determine_letter_grade(78) AS grade FROM DUAL
UNION ALL
SELECT 68 AS test_score, fn_determine_letter_grade(68) AS grade FROM DUAL
UNION ALL
SELECT 52 AS test_score, fn_determine_letter_grade(52) AS grade FROM DUAL
UNION ALL
SELECT 38 AS test_score, fn_determine_letter_grade(38) AS grade FROM DUAL;

PROMPT ============================================================================
PROMPT TEST 6: Student Academic & Financial Profile using fn_get_student_summary
PROMPT Demonstrates: User-Defined Record, %ROWTYPE, String Formatting
PROMPT ============================================================================

BEGIN
    DBMS_OUTPUT.PUT_LINE(fn_get_student_summary(1001));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(fn_get_student_summary(1002));
END;
/

PROMPT ============================================================================
PROMPT TEST 7: Reconcile and Update Tuition Balances (sp_update_tuition_balance)
PROMPT Demonstrates: Explicit Cursor (OPEN, FETCH, CLOSE), Implicit Cursor (UPDATE)
PROMPT ============================================================================

DECLARE
    v_updated_cnt NUMBER;
BEGIN
    sp_update_tuition_balance(
        p_student_id    => NULL, -- Process all students
        p_updated_count => v_updated_cnt
    );
    DBMS_OUTPUT.PUT_LINE('Total student balances reconciled: ' || v_updated_cnt);
END;
/

PROMPT Verifying Updated Student Balances:
SELECT student_id, student_reg_no, first_name, last_name, balance_due
FROM students
WHERE student_id IN (1001, 1002, 1003, 1004);

PROMPT ============================================================================
PROMPT ALL SUCCESSFUL TEST CASES EXECUTED SUCCESSFULLY!
PROMPT ============================================================================
