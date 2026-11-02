CREATE OR REPLACE PROCEDURE sp_bulk_process_grades (
    p_course_id       IN  courses.course_id%TYPE,
    p_semester        IN  VARCHAR2,
    p_processed_count OUT NUMBER,
    p_error_count     OUT NUMBER,
    p_status_message  OUT VARCHAR2
)
IS
    -- ============================================================================
    -- PROCEDURE: sp_bulk_process_grades
    -- DESCRIPTION: Performs bulk calculation and assignment of final grades for
    --              all enrolled students in a course for a given semester.
    -- CONCEPTS: Collections (Nested Tables, VARRAY, Associative Arrays),
    --           Bulk Processing (BULK COLLECT with LIMIT, FORALL with SAVE EXCEPTIONS),
    --           Bulk Exception Handling (ORA-24381, SQL%BULK_EXCEPTIONS),
    --           Audit trail logging.
    -- ============================================================================

    -- 1. VARRAY: Assessment weighting distribution (Index 1: Midterm 40%, Index 2: Final 60%)
    TYPE t_weights_varray IS VARRAY(2) OF NUMBER(3,2);
    v_assessment_weights t_weights_varray := t_weights_varray(0.40, 0.60);

    -- 2. Associative Array: Grade scale to quality points lookup
    TYPE t_grade_point_map IS TABLE OF NUMBER(3,2) INDEX BY VARCHAR2(5);
    v_grade_points t_grade_point_map;

    -- 3. Cursor for retrieving pending enrollments
    CURSOR c_pending_enrollments IS
        SELECT enrollment_id,
               student_id,
               course_id,
               semester,
               academic_year,
               midterm_score,
               final_score,
               total_score,
               letter_grade,
               grade_point,
               enrollment_status,
               enrolled_at
        FROM enrollments
        WHERE course_id = p_course_id
          AND semester = p_semester
          AND enrollment_status = 'ENROLLED'
          AND midterm_score IS NOT NULL
          AND final_score IS NOT NULL;

    -- 4. Nested Table Collection of enrollment records
    TYPE t_enrollment_table IS TABLE OF c_pending_enrollments%ROWTYPE;
    v_enrollments t_enrollment_table;

    -- Batch size for bulk collection
    c_batch_size CONSTANT PLS_INTEGER := 100;

    -- Exception handling for FORALL SAVE EXCEPTIONS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(bulk_errors, -24381);

    v_calc_total NUMBER(5,2);
    v_grade      VARCHAR2(5);
    v_pt         NUMBER(3,2);
    v_err_idx    NUMBER;
    v_err_code   NUMBER;
BEGIN
    p_processed_count := 0;
    p_error_count     := 0;
    p_status_message  := 'COMPLETED';

    -- Initialize Grade Point Map
    v_grade_points('A')  := 4.00;
    v_grade_points('A-') := 3.75;
    v_grade_points('B+') := 3.50;
    v_grade_points('B')  := 3.00;
    v_grade_points('B-') := 2.75;
    v_grade_points('C+') := 2.50;
    v_grade_points('C')  := 2.00;
    v_grade_points('C-') := 1.75;
    v_grade_points('D')  := 1.00;
    v_grade_points('F')  := 0.00;

    OPEN c_pending_enrollments;
    LOOP
        -- BULK COLLECT with LIMIT to optimize memory consumption
        FETCH c_pending_enrollments BULK COLLECT INTO v_enrollments LIMIT c_batch_size;
        EXIT WHEN v_enrollments.COUNT = 0;

        -- Process in-memory collection: compute weighted totals and assign grades
        FOR i IN 1..v_enrollments.COUNT LOOP
            -- Midterm (max 40) + Final (max 60) direct sum or weighted calculation
            v_calc_total := v_enrollments(i).midterm_score + v_enrollments(i).final_score;
            v_grade      := fn_determine_letter_grade(v_calc_total);

            IF v_grade_points.EXISTS(v_grade) THEN
                v_pt := v_grade_points(v_grade);
            ELSE
                v_pt := 0.00;
            END IF;

            v_enrollments(i).total_score       := v_calc_total;
            v_enrollments(i).letter_grade      := v_grade;
            v_enrollments(i).grade_point       := v_pt;
            v_enrollments(i).enrollment_status := 'COMPLETED';
        END LOOP;

        -- Bulk Update using FORALL with SAVE EXCEPTIONS
        BEGIN
            FORALL idx IN 1..v_enrollments.COUNT SAVE EXCEPTIONS
                UPDATE enrollments
                SET total_score       = v_enrollments(idx).total_score,
                    letter_grade      = v_enrollments(idx).letter_grade,
                    grade_point       = v_enrollments(idx).grade_point,
                    enrollment_status = v_enrollments(idx).enrollment_status
                WHERE enrollment_id = v_enrollments(idx).enrollment_id;

            p_processed_count := p_processed_count + v_enrollments.COUNT;

        EXCEPTION
            WHEN bulk_errors THEN
                p_error_count := p_error_count + SQL%BULK_EXCEPTIONS.COUNT;
                p_processed_count := p_processed_count + (v_enrollments.COUNT - SQL%BULK_EXCEPTIONS.COUNT);

                -- Iterate through bulk exceptions and log each failed record
                FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                    v_err_idx  := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
                    v_err_code := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;

                    INSERT INTO application_error_log (
                        source_unit,
                        error_code,
                        error_message,
                        error_backtrace,
                        context_info
                    ) VALUES (
                        'sp_bulk_process_grades',
                        v_err_code,
                        'Bulk update error on enrollment_id: ' || v_enrollments(v_err_idx).enrollment_id,
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                        'EnrollmentID=' || v_enrollments(v_err_idx).enrollment_id || 
                        ', StudentID=' || v_enrollments(v_err_idx).student_id
                    );
                END LOOP;
        END;

        -- Bulk Audit trail logging for processed records
        FORALL k IN 1..v_enrollments.COUNT
            INSERT INTO grade_audit_log (
                enrollment_id,
                old_total_score,
                new_total_score,
                old_letter_grade,
                new_letter_grade,
                changed_by,
                change_date,
                remarks
            ) VALUES (
                v_enrollments(k).enrollment_id,
                NULL,
                v_enrollments(k).total_score,
                NULL,
                v_enrollments(k).letter_grade,
                USER,
                SYSTIMESTAMP,
                'Automated bulk grade processing for course ' || p_course_id || ' (' || p_semester || ')'
            );

    END LOOP;

    CLOSE c_pending_enrollments;

    p_status_message := 'COMPLETED: ' || p_processed_count || ' records processed successfully. ' ||
                        p_error_count || ' records encountered errors.';
    
    DBMS_OUTPUT.PUT_LINE(p_status_message);

EXCEPTION
    WHEN OTHERS THEN
        IF c_pending_enrollments%ISOPEN THEN
            CLOSE c_pending_enrollments;
        END IF;
        p_status_message := 'FAILED: Unexpected error in sp_bulk_process_grades: ' || SQLERRM;
        INSERT INTO application_error_log (source_unit, error_code, error_message, error_backtrace, context_info)
        VALUES ('sp_bulk_process_grades', SQLCODE, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                'CourseID=' || p_course_id || ', Semester=' || p_semester);
        RAISE_APPLICATION_ERROR(-20099, p_status_message);
END sp_bulk_process_grades;
/
