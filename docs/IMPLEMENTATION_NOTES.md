# Implementation & Performance Analysis Notes

**Course**: Database Development with PL/SQL (INSY 8311)  
**Instructor**: Eric Maniraguha (`eric.maniraguha@auca.ac.rw`)  
**Teaching Assistant**: Afanyu Emmanuel  
**Class**: Group Assignment IV – Advanced Oracle PL/SQL Programming  
**Students**:
- **MUSAFIRI Arnold** — Student ID: `20252IMA134`
- **INGABIRE Kevin** — Student ID: `27780`

---

## 1. System Overview & Architecture

The **AUCA Student Academic & Financial Management System** addresses the critical operational lifecycle of higher education institutions: student course registrations, academic standing evaluations, grade batching, and student tuition financial ledger reconciliation.

The system is constructed with strict modularity, separation of concerns, and robust transactional integrity across Oracle Database 23c / SQL Developer.

```
+-----------------------------------------------------------------------------------+
|                               PL/SQL APPLICATION LAYER                            |
|                                                                                   |
|  +----------------------------+   +------------------------+   +---------------+  |
|  | sp_register_student_course |   | sp_bulk_process_grades |   | fn_calc_gpa   |  |
|  +----------------------------+   +------------------------+   +---------------+  |
|                 |                              |                        |         |
|  +----------------------------+   +------------------------+   +---------------+  |
|  | sp_update_tuition_balance  |   | fn_determine_grade     |   | fn_get_summary|  |
|  +----------------------------+   +------------------------+   +---------------+  |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                                RELATIONAL SCHEMA                                  |
|                                                                                   |
|   DEPARTMENTS <----+ COURSES <--------+ ENROLLMENTS +-----> GRADE_AUDIT_LOG       |
|          ^             ^                     |                                    |
|          |             |                     v                                    |
|          +--------- STUDENTS <----+ STUDENT_FINANCIAL_LOG                         |
|                       |                                                           |
|                       +-----------> APPLICATION_ERROR_LOG                         |
+-----------------------------------------------------------------------------------+
```

---

## 2. Records Implementation

PL/SQL records permit developers to treat heterogeneous but logically related fields as a singular unit of data, mirroring composite database entities in memory.

### 2.1 User-Defined Records
User-defined records were declared to represent composite data structures that do not map directly to a single table row:
- **`t_registration_rec`** in [`sp_register_student_course.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_register_student_course.sql):
  ```sql
  TYPE t_registration_rec IS RECORD (
      student_id     students.student_id%TYPE,
      course_id      courses.course_id%TYPE,
      credits        courses.credits%TYPE,
      fee_per_credit courses.fee_per_credit%TYPE,
      total_fee      NUMBER(12,2),
      semester       VARCHAR2(20),
      academic_year  VARCHAR2(10)
  );
  ```
  *Benefit*: Encapsulates all transactional parameters needed to create an enrollment and charge tuition simultaneously without carrying loose parameters across procedural stages.
- **`t_student_profile_rec`** in [`fn_get_student_summary.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/02_functions/fn_get_student_summary.sql):
  Aggregates personal demographics, academic indicators (GPA, completed hours), and financial account status into a single structured record for string serialization.

### 2.2 `%ROWTYPE` Records
`%ROWTYPE` allows PL/SQL to dynamically inherit the complete column definition of an underlying database table or cursor:
- `v_student students%ROWTYPE;` in [`sp_register_student_course.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_register_student_course.sql)
- `v_course courses%ROWTYPE;` in [`sp_register_student_course.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_register_student_course.sql)
- `c_pending_enrollments%ROWTYPE` in [`sp_bulk_process_grades.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_bulk_process_grades.sql)

*Maintenance Advantage*: If columns are added, removed, or altered in `STUDENTS` or `COURSES`, the PL/SQL units automatically adapt upon recompilation without requiring structural code alterations.

---

## 3. Collections Implementation

Three distinct collection categories were utilized, each chosen according to its memory model and indexing characteristics:

| Collection Category | Type Declaration | Indexing / Bound | Practical Usage in System |
| :--- | :--- | :--- | :--- |
| **Associative Array** (`INDEX BY`) | `TYPE t_grade_point_map IS TABLE OF NUMBER(3,2) INDEX BY VARCHAR2(5);` | Sparse key-value lookup indexed by string | High-speed in-memory grade-point scale caching (`fn_determine_letter_grade`, `sp_bulk_process_grades`) |
| **Nested Table** | `TYPE t_enrollment_table IS TABLE OF c_pending_enrollments%ROWTYPE;` | Unbounded, dense sequential | In-memory batch array populated by `BULK COLLECT` |
| **VARRAY** | `TYPE t_weights_varray IS VARRAY(2) OF NUMBER(3,2);` | Fixed maximum bound (2 elements) | Preserving strict ordered weights for Midterm (0.40) and Final Exam (0.60) |

---

## 4. Cursor Management: Implicit vs Explicit

### 4.1 Implicit Cursors
Every DML command (`INSERT`, `UPDATE`, `DELETE`) and single-row `SELECT ... INTO` creates an internal implicit cursor managed by Oracle. Our implementation explicitly queries cursor attributes:
- **`SQL%ROWCOUNT`**: Asserts the exact number of rows modified.
- **`SQL%FOUND`**: Verifies that the DML operation modified at least one row.
- **`SQL%NOTFOUND`**: Triggers custom exceptions if an updated target (e.g., student balance) was not touched.

Example from [`sp_register_student_course.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_register_student_course.sql):
```sql
UPDATE students
SET balance_due = balance_due + v_reg_detail.total_fee
WHERE student_id = v_reg_detail.student_id;

IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20031, 'Student balance update failed: student record not found.');
END IF;
```

### 4.2 Explicit Cursors
Explicit cursors provide full programmatic control over query work areas. They are managed through their standard four-stage lifecycle:
1. **`OPEN`**: Evaluates parameters and builds the active query result set.
2. **`FETCH`**: Retrieves candidate tuples into records or collections.
3. **Status Check**: Inspects `%NOTFOUND` to terminate processing loops, and `%ROWCOUNT` to assert non-empty datasets.
4. **`CLOSE`**: Releases server memory and locks back to the Oracle PGA/SGA.

Implemented in:
- [`fn_calculate_gpa.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/02_functions/fn_calculate_gpa.sql): Iterates through completed courses.
- [`sp_update_tuition_balance.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_update_tuition_balance.sql): Reconciles student accounts sequentially.

---

## 5. Bulk Processing & Performance Considerations

### 5.1 The Context-Switching Problem
When executing SQL within a PL/SQL loop row by row (commonly known as "row-by-row" or "slow-by-slow" processing):
- Every iteration forces a context switch between the **PL/SQL runtime engine** and the **SQL execution engine**.
- For 10,000 student records, 20,000 to 30,000 context switches occur, degrading CPU efficiency, latch acquisition, and transaction throughput.

```
Conventional Row-by-Row Processing:
PL/SQL Engine  ---> [Switch 1] ---> SQL Engine (SELECT / UPDATE 1)
PL/SQL Engine <--- [Switch 2] <--- SQL Engine
PL/SQL Engine  ---> [Switch 3] ---> SQL Engine (SELECT / UPDATE 2)
PL/SQL Engine <--- [Switch 4] <--- SQL Engine
... (repeats for every single row)

Optimized Bulk Processing:
PL/SQL Engine ===[ 1 Bulk Request ]===> SQL Engine (Processes 100 rows at once)
PL/SQL Engine <==[ 1 Bulk Response ]=== SQL Engine
```

### 5.2 Bulk Collect with `LIMIT`
In [`sp_bulk_process_grades.sql`](file:///c:/Users/PARADOX/Videos/work%20IV/01_procedures/sp_bulk_process_grades.sql), `BULK COLLECT` fetches tuples into memory collections. To prevent exhausting process memory (PGA) on large institutional tables, the `LIMIT c_batch_size` (set to 100) clause bounds each fetch:
```sql
FETCH c_pending_enrollments BULK COLLECT INTO v_enrollments LIMIT c_batch_size;
EXIT WHEN v_enrollments.COUNT = 0;
```

### 5.3 `FORALL` DML Execution
Rather than looping through SQL `UPDATE` statements, `FORALL` dispatches the entire batch in a single engine invocation:
```sql
FORALL idx IN 1..v_enrollments.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
    SET total_score       = v_enrollments(idx).total_score,
        letter_grade      = v_enrollments(idx).letter_grade,
        grade_point       = v_enrollments(idx).grade_point,
        enrollment_status = v_enrollments(idx).enrollment_status
    WHERE enrollment_id = v_enrollments(idx).enrollment_id;
```

### 5.4 Bulk Exception Handling (`SAVE EXCEPTIONS`)
By default, an error on row 42 of a bulk operation terminates the entire batch and rolls back previous rows. Using `SAVE EXCEPTIONS`:
- Oracle intercepts errors in `SQL%BULK_EXCEPTIONS` and continues executing the remainder of the batch.
- The `ORA-24381: error(s) in array DML` is trapped.
- We loop through `1..SQL%BULK_EXCEPTIONS.COUNT` to log:
  - `SQL%BULK_EXCEPTIONS(i).ERROR_INDEX` (the exact failed element)
  - `SQL%BULK_EXCEPTIONS(i).ERROR_CODE` (the specific Oracle error code)
- Failures are inserted into `APPLICATION_ERROR_LOG` while all valid student grades commit successfully!

---

## 6. Exception Handling Matrix

The application employs a 3-tier defense strategy:

| Category | Identifier / Code | Origin / Cause | Handling Technique |
| :--- | :--- | :--- | :--- |
| **Predefined Exceptions** | `NO_DATA_FOUND` (ORA-01403) | Non-existent student/course ID | Trapped in `SELECT INTO`, converted to descriptive user message |
| | `TOO_MANY_ROWS` (ORA-01422) | Primary/Unique key anomaly | Caught in profile inquiry |
| | `ZERO_DIVIDE` (ORA-01476) | Student with 0 completed credit hours | Handled inside `fn_calculate_gpa`, returns 0.00 |
| | `DUP_VAL_ON_INDEX` (ORA-00001) | Student re-registering for the same course | Trapped and reported with semester details |
| **User-Defined Exceptions** | `e_capacity_exceeded` | Active course registration >= max_capacity | `RAISE_APPLICATION_ERROR(-20036, ...)` |
| | `e_student_suspended` | Student academic status = 'SUSPENDED' | `RAISE_APPLICATION_ERROR(-20034, ...)` |
| | `e_course_inactive` | Course status = 'INACTIVE' | `RAISE_APPLICATION_ERROR(-20035, ...)` |
| | `e_invalid_score` | Total score < 0 or > 100 | `RAISE_APPLICATION_ERROR(-20010, ...)` |
| **System Traps & Logging** | `bulk_errors` (ORA-24381) | One or more failures inside `FORALL` | `PRAGMA EXCEPTION_INIT`, mapped to `APPLICATION_ERROR_LOG` |
| | `WHEN OTHERS` | Unanticipated runtime anomalies | Formatted with `DBMS_UTILITY.FORMAT_ERROR_BACKTRACE` and persistent logging |

---

## 7. Verification Summary

All test cases in `03_tests/test_success_cases.sql` and `03_tests/test_error_cases.sql` execute deterministically:
1. Multi-course registration succeeds and calculates tuition accurately.
2. Capacity limit strictly blocks excess applicants.
3. Inactive course registration is rejected cleanly.
4. Bulk grade updates run in chunks, calculating GPA accurately and writing audit records.
5. All exceptions log errors to `APPLICATION_ERROR_LOG` with backtraces without data corruption.
