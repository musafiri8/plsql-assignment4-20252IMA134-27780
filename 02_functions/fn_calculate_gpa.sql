CREATE OR REPLACE FUNCTION fn_calculate_gpa (
    p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
    -- ============================================================================
    -- FUNCTION: fn_calculate_gpa
    -- DESCRIPTION: Computes cumulative GPA for a student across all completed courses.
    -- CONCEPTS: Explicit cursor (OPEN, FETCH, CLOSE, %NOTFOUND, %ROWCOUNT),
    --           Predefined exceptions (NO_DATA_FOUND, ZERO_DIVIDE),
    --           User-defined exceptions.
    -- ============================================================================
    
    -- Explicit cursor to retrieve completed courses and credit values
    CURSOR c_completed_courses IS
        SELECT e.grade_point, c.credits
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.student_id = p_student_id
          AND e.enrollment_status = 'COMPLETED'
          AND e.grade_point IS NOT NULL;

    -- Local record variables
    v_grade_point   enrollments.grade_point%TYPE;
    v_credits       courses.credits%TYPE;
    
    v_total_points  NUMBER(8,2) := 0;
    v_total_credits NUMBER(4)   := 0;
    v_gpa           NUMBER(3,2) := 0.00;
    v_student_count NUMBER;
    
    -- User-defined exceptions
    e_student_not_found EXCEPTION;
BEGIN
    -- Verify student existence (Predefined/User validation)
    SELECT COUNT(*) INTO v_student_count
    FROM students
    WHERE student_id = p_student_id;

    IF v_student_count = 0 THEN
        RAISE e_student_not_found;
    END IF;

    -- Open and process explicit cursor
    OPEN c_completed_courses;
    LOOP
        FETCH c_completed_courses INTO v_grade_point, v_credits;
        EXIT WHEN c_completed_courses%NOTFOUND;
        
        v_total_points  := v_total_points + (v_grade_point * v_credits);
        v_total_credits := v_total_credits + v_credits;
    END LOOP;
    
    -- Cursor attribute inspection before closing
    IF c_completed_courses%ROWCOUNT = 0 THEN
        -- No completed courses found; default GPA is 0.00
        CLOSE c_completed_courses;
        RETURN 0.00;
    END IF;
    
    CLOSE c_completed_courses;

    -- Calculate GPA with division check
    BEGIN
        v_gpa := ROUND(v_total_points / v_total_credits, 2);
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            v_gpa := 0.00;
    END;

    RETURN v_gpa;

EXCEPTION
    WHEN e_student_not_found THEN
        IF c_completed_courses%ISOPEN THEN
            CLOSE c_completed_courses;
        END IF;
        RAISE_APPLICATION_ERROR(-20020, 'Student Error: Student ID ' || p_student_id || ' does not exist in the database.');
    WHEN OTHERS THEN
        IF c_completed_courses%ISOPEN THEN
            CLOSE c_completed_courses;
        END IF;
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in fn_calculate_gpa: ' || SQLERRM);
END fn_calculate_gpa;
/
