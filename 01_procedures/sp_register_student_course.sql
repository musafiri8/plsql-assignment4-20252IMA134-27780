CREATE OR REPLACE PROCEDURE sp_register_student_course (
    p_student_id       IN  students.student_id%TYPE,
    p_course_id        IN  courses.course_id%TYPE,
    p_semester         IN  VARCHAR2,
    p_academic_year    IN  VARCHAR2,
    p_enrollment_id    OUT NUMBER,
    p_tuition_charged  OUT NUMBER,
    p_status_message   OUT VARCHAR2
)
IS
    -- ============================================================================
    -- PROCEDURE: sp_register_student_course
    -- DESCRIPTION: Validates eligibility, checks course capacity, registers a
    --              student, logs tuition charges, and updates student balance.
    -- CONCEPTS: User-defined Record, %ROWTYPE, Implicit Cursors (SQL%ROWCOUNT,
    --           SQL%FOUND, SQL%NOTFOUND), Predefined exceptions (DUP_VAL_ON_INDEX,
    --           NO_DATA_FOUND), User-defined exceptions, RAISE_APPLICATION_ERROR.
    -- ============================================================================

    -- User-defined record type to bundle registration transaction details
    TYPE t_registration_rec IS RECORD (
        student_id     students.student_id%TYPE,
        course_id      courses.course_id%TYPE,
        credits        courses.credits%TYPE,
        fee_per_credit courses.fee_per_credit%TYPE,
        total_fee      NUMBER(12,2),
        semester       VARCHAR2(20),
        academic_year  VARCHAR2(10)
    );

    v_reg_detail        t_registration_rec;
    v_student           students%ROWTYPE;
    v_course            courses%ROWTYPE;
    v_current_enrolled  NUMBER := 0;

    -- User-defined exceptions
    e_student_suspended EXCEPTION;
    e_course_inactive   EXCEPTION;
    e_capacity_exceeded EXCEPTION;
BEGIN
    -- Initialize OUT parameters
    p_enrollment_id   := NULL;
    p_tuition_charged := 0;
    p_status_message  := 'FAILED';

    -- 1. Fetch Student using %ROWTYPE (Handles NO_DATA_FOUND automatically)
    SELECT * INTO v_student
    FROM students
    WHERE student_id = p_student_id;

    -- Check student eligibility
    IF v_student.academic_status = 'SUSPENDED' THEN
        RAISE e_student_suspended;
    END IF;

    -- 2. Fetch Course using %ROWTYPE
    SELECT * INTO v_course
    FROM courses
    WHERE course_id = p_course_id;

    -- Check course status
    IF v_course.status != 'ACTIVE' THEN
        RAISE e_course_inactive;
    END IF;

    -- 3. Check Course Capacity
    SELECT COUNT(*)
    INTO   v_current_enrolled
    FROM   enrollments
    WHERE  course_id = p_course_id
      AND  semester = p_semester
      AND  academic_year = p_academic_year
      AND  enrollment_status = 'ENROLLED';

    IF v_current_enrolled >= v_course.max_capacity THEN
        RAISE e_capacity_exceeded;
    END IF;

    -- 4. Calculate Tuition in User-Defined Record
    v_reg_detail.student_id     := p_student_id;
    v_reg_detail.course_id      := p_course_id;
    v_reg_detail.credits        := v_course.credits;
    v_reg_detail.fee_per_credit := v_course.fee_per_credit;
    v_reg_detail.total_fee      := v_course.credits * v_course.fee_per_credit;
    v_reg_detail.semester       := p_semester;
    v_reg_detail.academic_year  := p_academic_year;

    -- 5. Insert into ENROLLMENTS table (Implicit Cursor)
    INSERT INTO enrollments (
        student_id,
        course_id,
        semester,
        academic_year,
        enrollment_status
    ) VALUES (
        v_reg_detail.student_id,
        v_reg_detail.course_id,
        v_reg_detail.semester,
        v_reg_detail.academic_year,
        'ENROLLED'
    ) RETURNING enrollment_id INTO p_enrollment_id;

    -- Implicit cursor inspection
    IF NOT SQL%FOUND OR SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Registration failed: unable to create enrollment record.');
    END IF;

    -- 6. Insert Financial Transaction (Implicit Cursor)
    INSERT INTO student_financial_log (
        student_id,
        course_id,
        txn_type,
        amount,
        txn_date,
        description
    ) VALUES (
        v_reg_detail.student_id,
        v_reg_detail.course_id,
        'TUITION_CHARGE',
        v_reg_detail.total_fee,
        SYSDATE,
        'Tuition fee for ' || v_course.course_code || ' (' || v_reg_detail.credits || ' credits)'
    );

    -- 7. Update Student Balance Due (Implicit Cursor)
    UPDATE students
    SET balance_due = balance_due + v_reg_detail.total_fee
    WHERE student_id = v_reg_detail.student_id;

    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20031, 'Student balance update failed: student record not found.');
    END IF;

    p_tuition_charged := v_reg_detail.total_fee;
    p_status_message  := 'SUCCESS: Enrolled student ' || v_student.student_reg_no || 
                         ' in ' || v_course.course_code || 
                         ' (Enrollment ID: ' || p_enrollment_id || 
                         ', Fee: RWF ' || p_tuition_charged || ').';

    DBMS_OUTPUT.PUT_LINE(p_status_message);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status_message := 'ERROR: Student ID ' || p_student_id || ' or Course ID ' || p_course_id || ' does not exist.';
        RAISE_APPLICATION_ERROR(-20032, p_status_message);

    WHEN DUP_VAL_ON_INDEX THEN
        p_status_message := 'ERROR: Student is already registered for this course in ' || p_semester || ' (' || p_academic_year || ').';
        RAISE_APPLICATION_ERROR(-20033, p_status_message);

    WHEN e_student_suspended THEN
        p_status_message := 'ERROR: Student ' || p_student_id || ' is academically SUSPENDED and cannot register for courses.';
        RAISE_APPLICATION_ERROR(-20034, p_status_message);

    WHEN e_course_inactive THEN
        p_status_message := 'ERROR: Course ID ' || p_course_id || ' is INACTIVE and not accepting registrations.';
        RAISE_APPLICATION_ERROR(-20035, p_status_message);

    WHEN e_capacity_exceeded THEN
        p_status_message := 'ERROR: Course ' || v_course.course_code || ' has reached full capacity (' || v_course.max_capacity || ' students).';
        RAISE_APPLICATION_ERROR(-20036, p_status_message);

    WHEN OTHERS THEN
        p_status_message := 'UNEXPECTED ERROR in sp_register_student_course: ' || SQLERRM;
        -- Log into application_error_log
        INSERT INTO application_error_log (source_unit, error_code, error_message, error_backtrace, context_info)
        VALUES ('sp_register_student_course', SQLCODE, SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 
                'StudentID=' || p_student_id || ', CourseID=' || p_course_id);
        RAISE_APPLICATION_ERROR(-20099, p_status_message);
END sp_register_student_course;
/
