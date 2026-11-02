CREATE OR REPLACE FUNCTION fn_get_student_summary (
    p_student_id IN students.student_id%TYPE
) RETURN VARCHAR2
IS
    -- ============================================================================
    -- FUNCTION: fn_get_student_summary
    -- DESCRIPTION: Generates a formatted academic and financial profile for a student.
    -- CONCEPTS: User-defined Record Type, %ROWTYPE, Implicit Cursor with INTO,
    --           Predefined exceptions (NO_DATA_FOUND, TOO_MANY_ROWS),
    --           Function reusability.
    -- ============================================================================

    -- User-defined record to structure student profile data
    TYPE t_student_profile_rec IS RECORD (
        student_id      students.student_id%TYPE,
        full_name       VARCHAR2(100),
        reg_number      students.student_reg_no%TYPE,
        department      departments.dept_name%TYPE,
        completed_hours NUMBER(4),
        cumulative_gpa  NUMBER(3,2),
        academic_status students.academic_status%TYPE,
        balance_due     students.balance_due%TYPE
    );

    v_profile      t_student_profile_rec;
    v_dept_name    departments.dept_name%TYPE;
    v_total_hours  NUMBER(4) := 0;
    v_output       VARCHAR2(4000);
BEGIN
    -- Query student basic info into record fields
    SELECT s.student_id,
           s.first_name || ' ' || s.last_name,
           s.student_reg_no,
           d.dept_name,
           s.academic_status,
           s.balance_due
    INTO   v_profile.student_id,
           v_profile.full_name,
           v_profile.reg_number,
           v_profile.department,
           v_profile.academic_status,
           v_profile.balance_due
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    WHERE s.student_id = p_student_id;

    -- Query total completed credit hours
    SELECT NVL(SUM(c.credits), 0)
    INTO   v_total_hours
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.student_id = p_student_id
      AND e.enrollment_status = 'COMPLETED';

    v_profile.completed_hours := v_total_hours;
    v_profile.cumulative_gpa  := fn_calculate_gpa(p_student_id);

    -- Format summary report
    v_output := '------------------------------------------------------------' || CHR(10) ||
                'STUDENT ACADEMIC & FINANCIAL SUMMARY' || CHR(10) ||
                '------------------------------------------------------------' || CHR(10) ||
                'Student ID     : ' || v_profile.student_id || CHR(10) ||
                'Registration No: ' || v_profile.reg_number || CHR(10) ||
                'Student Name   : ' || v_profile.full_name || CHR(10) ||
                'Department     : ' || v_profile.department || CHR(10) ||
                'Completed Cr.  : ' || v_profile.completed_hours || ' credits' || CHR(10) ||
                'Cumulative GPA : ' || TO_CHAR(v_profile.cumulative_gpa, '0.99') || CHR(10) ||
                'Academic Status: ' || v_profile.academic_status || CHR(10) ||
                'Tuition Balance: RWF ' || TO_CHAR(v_profile.balance_due, '999,999,990.00') || CHR(10) ||
                '------------------------------------------------------------';

    RETURN v_output;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'Student Profile Error: Student ID ' || p_student_id || ' was not found.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Integrity Error: Multiple records found for Student ID ' || p_student_id || '.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in fn_get_student_summary: ' || SQLERRM);
END fn_get_student_summary;
/
