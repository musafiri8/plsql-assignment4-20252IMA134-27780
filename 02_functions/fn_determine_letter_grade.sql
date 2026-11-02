CREATE OR REPLACE FUNCTION fn_determine_letter_grade (
    p_total_score IN NUMBER
) RETURN VARCHAR2
IS
    -- ============================================================================
    -- FUNCTION: fn_determine_letter_grade
    -- DESCRIPTION: Converts a numerical score (0-100) into an official letter grade
    --              using AUCA standard grading scale with Associative Array caching.
    -- CONCEPTS: Collections (Associative Array INDEX BY VARCHAR2), 
    --           User-defined Exception, RAISE_APPLICATION_ERROR.
    -- ============================================================================
    
    -- Associative array to store grade points for verification
    TYPE t_grade_scale_map IS TABLE OF NUMBER(3,2) INDEX BY VARCHAR2(5);
    v_grade_scales t_grade_scale_map;
    
    v_letter_grade VARCHAR2(5);
    
    -- User-defined exception for invalid score range
    e_invalid_score EXCEPTION;
BEGIN
    -- Input validation
    IF p_total_score IS NULL THEN
        RETURN 'I'; -- Incomplete
    END IF;
    
    IF p_total_score < 0 OR p_total_score > 100 THEN
        RAISE e_invalid_score;
    END IF;

    -- Initialize associative array mapping
    v_grade_scales('A')  := 4.00;
    v_grade_scales('A-') := 3.75;
    v_grade_scales('B+') := 3.50;
    v_grade_scales('B')  := 3.00;
    v_grade_scales('B-') := 2.75;
    v_grade_scales('C+') := 2.50;
    v_grade_scales('C')  := 2.00;
    v_grade_scales('C-') := 1.75;
    v_grade_scales('D')  := 1.00;
    v_grade_scales('F')  := 0.00;

    -- Determine letter grade based on institutional thresholds
    IF p_total_score >= 90.00 THEN
        v_letter_grade := 'A';
    ELSIF p_total_score >= 85.00 THEN
        v_letter_grade := 'A-';
    ELSIF p_total_score >= 80.00 THEN
        v_letter_grade := 'B+';
    ELSIF p_total_score >= 75.00 THEN
        v_letter_grade := 'B';
    ELSIF p_total_score >= 70.00 THEN
        v_letter_grade := 'B-';
    ELSIF p_total_score >= 65.00 THEN
        v_letter_grade := 'C+';
    ELSIF p_total_score >= 60.00 THEN
        v_letter_grade := 'C';
    ELSIF p_total_score >= 55.00 THEN
        v_letter_grade := 'C-';
    ELSIF p_total_score >= 50.00 THEN
        v_letter_grade := 'D';
    ELSE
        v_letter_grade := 'F';
    END IF;

    -- Confirm validity against associative array
    IF NOT v_grade_scales.EXISTS(v_letter_grade) THEN
        v_letter_grade := 'I';
    END IF;

    RETURN v_letter_grade;

EXCEPTION
    WHEN e_invalid_score THEN
        RAISE_APPLICATION_ERROR(-20010, 'Grade Error: Total score ' || p_total_score || ' is outside acceptable range (0.00 - 100.00).');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in fn_determine_letter_grade: ' || SQLERRM);
END fn_determine_letter_grade;
/
