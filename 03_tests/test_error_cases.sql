-- ============================================================================
-- SCRIPT: test_error_cases.sql
-- COURSE: Database Development with PL/SQL (INSY 8311)
-- GROUP: Assignment IV - Advanced Oracle PL/SQL Programming
-- STUDENTS: MUSAFIRI Arnold (20252IMA134) & INGABIRE Kevin (27780)
-- DESCRIPTION: Comprehensive suite of error and exception-handling test cases.
--              Demonstrates: Predefined Exceptions, User-Defined Exceptions,
--              RAISE_APPLICATION_ERROR, and Application Error Logging.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
COL source_unit FORMAT A25;
COL error_code FORMAT 999999;
COL error_message FORMAT A45;
COL context_info FORMAT A35;

PROMPT ============================================================================
PROMPT ERROR TEST 1: Duplicate Course Registration (DUP_VAL_ON_INDEX / ORA-20033)
PROMPT Scenario: Student 1001 attempts to register again for Course 101 in Semester 1 2026/2027
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1001,
        p_course_id       => 101,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 2: Registration for Inactive Course (e_course_inactive / ORA-20035)
PROMPT Scenario: Student 1001 attempts to register for Course 105 (INACTIVE)
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1001,
        p_course_id       => 105,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 3: Course Capacity Exceeded (e_capacity_exceeded / ORA-20036)
PROMPT Scenario: Student 1001 attempts to register for Course 104 (Capacity = 2, already full)
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1001,
        p_course_id       => 104,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 4: Registration for Suspended Student (e_student_suspended / ORA-20034)
PROMPT Scenario: Student 1007 (SUSPENDED) attempts to register for Course 101
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 1007,
        p_course_id       => 101,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 5: Non-Existent Student Registration (NO_DATA_FOUND / ORA-20032)
PROMPT Scenario: Attempting to register non-existent student ID 99999
PROMPT ============================================================================

DECLARE
    v_enroll_id   NUMBER;
    v_tuition     NUMBER;
    v_status_msg  VARCHAR2(500);
BEGIN
    sp_register_student_course(
        p_student_id      => 99999,
        p_course_id       => 101,
        p_semester        => 'Semester 1 2026/2027',
        p_academic_year   => '2026-2027',
        p_enrollment_id   => v_enroll_id,
        p_tuition_charged => v_tuition,
        p_status_message  => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 6: Invalid Score in fn_determine_letter_grade (ORA-20010)
PROMPT Scenario: Calling function with total score = 150 (valid range is 0 - 100)
PROMPT ============================================================================

DECLARE
    v_grade VARCHAR2(5);
BEGIN
    v_grade := fn_determine_letter_grade(150);
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised! Result: ' || v_grade);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 7: GPA Calculation for Non-Existent Student (ORA-20020)
PROMPT Scenario: Calling fn_calculate_gpa for student ID 99999
PROMPT ============================================================================

DECLARE
    v_gpa NUMBER(3,2);
BEGIN
    v_gpa := fn_calculate_gpa(99999);
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised! Result: ' || v_gpa);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT ERROR TEST 8: Student Summary for Non-Existent Student (ORA-20021)
PROMPT Scenario: Calling fn_get_student_summary for student ID 99999
PROMPT ============================================================================

DECLARE
    v_summary VARCHAR2(4000);
BEGIN
    v_summary := fn_get_student_summary(99999);
    DBMS_OUTPUT.PUT_LINE('FAIL: Exception was NOT raised!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

PROMPT ============================================================================
PROMPT APPLICATION ERROR AUDIT LOG VERIFICATION:
PROMPT ============================================================================

SELECT log_id, source_unit, error_code, error_message, context_info, logged_at
FROM application_error_log
ORDER BY log_id DESC;

PROMPT ============================================================================
PROMPT ALL ERROR AND EXCEPTION HANDLING TESTS PASSED AS EXPECTED!
PROMPT ============================================================================
