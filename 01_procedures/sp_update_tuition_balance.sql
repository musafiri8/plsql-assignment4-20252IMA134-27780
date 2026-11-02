CREATE OR REPLACE PROCEDURE sp_update_tuition_balance (
    p_student_id     IN  students.student_id%TYPE DEFAULT NULL,
    p_updated_count  OUT NUMBER
)
IS
    -- ============================================================================
    -- PROCEDURE: sp_update_tuition_balance
    -- DESCRIPTION: Reconciles and updates student balance_due by computing the net
    --              difference between total charges and total credits/payments.
    -- CONCEPTS: Explicit Cursor (OPEN, FETCH, CLOSE, %NOTFOUND, %ROWCOUNT),
    --           Implicit Cursors (UPDATE with SQL%ROWCOUNT, SQL%FOUND),
    --           Exception handling, transaction integrity.
    -- ============================================================================

    -- Explicit cursor to iterate over active students
    CURSOR c_students IS
        SELECT student_id, student_reg_no, first_name || ' ' || last_name AS full_name
        FROM students
        WHERE (p_student_id IS NULL OR student_id = p_student_id);

    v_student_id    students.student_id%TYPE;
    v_reg_no        students.student_reg_no%TYPE;
    v_full_name     VARCHAR2(100);
    
    v_total_charges NUMBER(12,2) := 0;
    v_total_credits NUMBER(12,2) := 0;
    v_net_balance   NUMBER(12,2) := 0;

    e_no_students_found EXCEPTION;
BEGIN
    p_updated_count := 0;

    OPEN c_students;
    LOOP
        FETCH c_students INTO v_student_id, v_reg_no, v_full_name;
        EXIT WHEN c_students%NOTFOUND;

        -- 1. Compute total charges from financial log
        SELECT NVL(SUM(amount), 0)
        INTO   v_total_charges
        FROM   student_financial_log
        WHERE  student_id = v_student_id
          AND  txn_type = 'TUITION_CHARGE';

        -- 2. Compute total payments & waivers from financial log
        SELECT NVL(SUM(amount), 0)
        INTO   v_total_credits
        FROM   student_financial_log
        WHERE  student_id = v_student_id
          AND  txn_type IN ('PAYMENT', 'SCHOLARSHIP_DISCOUNT', 'FEE_WAIVER');

        v_net_balance := v_total_charges - v_total_credits;

        -- 3. Update student balance using Implicit Cursor
        UPDATE students
        SET balance_due = v_net_balance
        WHERE student_id = v_student_id;

        IF SQL%FOUND THEN
            p_updated_count := p_updated_count + SQL%ROWCOUNT;
            DBMS_OUTPUT.PUT_LINE('Reconciled student ' || v_reg_no || ' (' || v_full_name || 
                                 ') -> New Balance: RWF ' || TO_CHAR(v_net_balance, '999,999,990.00'));
        END IF;

    END LOOP;

    -- Inspect explicit cursor row count
    IF c_students%ROWCOUNT = 0 THEN
        CLOSE c_students;
        RAISE e_no_students_found;
    END IF;

    CLOSE c_students;

    DBMS_OUTPUT.PUT_LINE('Successfully updated ' || p_updated_count || ' student account balances.');

EXCEPTION
    WHEN e_no_students_found THEN
        IF c_students%ISOPEN THEN
            CLOSE c_students;
        END IF;
        RAISE_APPLICATION_ERROR(-20040, 'Balance Update Warning: No matching student found for ID ' || p_student_id);

    WHEN OTHERS THEN
        IF c_students%ISOPEN THEN
            CLOSE c_students;
        END IF;
        INSERT INTO application_error_log (
            source_unit,
            error_code,
            error_message,
            error_backtrace,
            context_info
        ) VALUES (
            'sp_update_tuition_balance',
            SQLCODE,
            SQLERRM,
            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            'StudentID=' || NVL(TO_CHAR(p_student_id), 'ALL')
        );
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in sp_update_tuition_balance: ' || SQLERRM);
END sp_update_tuition_balance;
/
