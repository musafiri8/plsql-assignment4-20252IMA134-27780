# Advanced Oracle PL/SQL Application: Student Academic & Financial Management System

**Course**: Database Development with PL/SQL (`INSY 8311`)  
**Assignment**: Group Assignment IV – Advanced Oracle PL/SQL Programming  
**Instructor**: Eric Maniraguha (`eric.maniraguha@auca.ac.rw`)  
**Teaching Assistant**: Afanyu Emmanuel  
**Submission Form**: [Google Form Submission](https://forms.gle/T97Ay3yeKCKBYf7t8)  
**Target Environment**: Oracle Database 23c / Oracle SQL Developer (Version 26.2.0.186.2220)

---

## 👥 Group Members

| Member Name | Student ID | Class Group | Role / Contribution |
| :--- | :--- | :--- | :--- |
| **MUSAFIRI Arnold** | `20252IMA134` | I | Schema Architecture, Bulk Processing (`sp_bulk_process_grades`), Explicit Cursors, Testing Harness |
| **INGABIRE Kevin** | `27780` | I | Records & Collections, Stored Procedures (`sp_register_student_course`, `sp_update_tuition_balance`), Functions (`fn_calculate_gpa`, `fn_determine_letter_grade`, `fn_get_student_summary`), Documentation |

---

## 📖 Practical Application Scenario

**System**: *AUCA EduTrack Pro – Academic Records, Course Enrollment, and Tuition Management System*

In higher educational institutions such as the Adventist University of Central Africa (AUCA), managing the student lifecycle involves high-volume data transactions spanning course catalog management, enrollment capacity gating, multi-course grade processing, cumulative GPA calculations, and student financial accounts.

This project delivers an enterprise-grade Oracle PL/SQL backend implementing:
1. **Course Registration with Integrity Constraints**: Enforces active status, prerequisites, and max student capacity limits while concurrently posting financial tuition charges.
2. **Bulk Grade Processing & Quality Point Calculation**: Evaluates in-memory score batches, computes weighted final marks, assigns institutional letter grades, and records audit trail entries without row-by-row overhead.
3. **Tuition Account Reconciliation**: Computes real-time account balances by reconciling charges against payments and scholarships.
4. **Resilient Exception Architecture**: Traps predefined Oracle errors, enforces domain invariants via custom application errors, and preserves batch continuity using bulk DML exception trapping (`SAVE EXCEPTIONS`).

---

## 🗂️ Repository Structure

```text
plsql-assignment4-20252IMA134-27780/
│
├── README.md                           # Group members, application description, how to run, AI acknowledgement
├── .gitignore                          # Standard git ignore for OS and Oracle SQL Developer cache
│
├── 00_schema/
│   ├── 01_create_tables.sql            # Tables, primary/foreign keys, checks, and constraints
│   └── 02_insert_sample_data.sql       # Seed data for departments, courses, students, enrollments, transactions
│
├── 01_procedures/
│   ├── sp_register_student_course.sql  # Course enrollment, user-defined record, %ROWTYPE, implicit cursors
│   ├── sp_bulk_process_grades.sql      # BULK COLLECT with LIMIT, FORALL with SAVE EXCEPTIONS, collections
│   └── sp_update_tuition_balance.sql   # Explicit cursor (OPEN/FETCH/CLOSE), implicit cursor updates
│
├── 02_functions/
│   ├── fn_determine_letter_grade.sql   # Associative array lookup, score-to-letter grading
│   ├── fn_calculate_gpa.sql            # Explicit cursor, ZERO_DIVIDE handling, SQL & PL/SQL callable
│   └── fn_get_student_summary.sql      # User-defined record, %ROWTYPE, student academic/financial profile
│
├── 03_tests/
│   ├── test_success_cases.sql          # Test suite verifying all functional and bulk execution flows
│   └── test_error_cases.sql            # Test suite verifying exceptions (DUP_VAL_ON_INDEX, ORA-20001..20040)
│
├── screenshots/
│   ├── README.md                       # Screenshot checklist and capture guidelines for SQL Developer
│   └── <test_name>_output.png          # Visual outputs captured from Oracle SQL Developer
│
└── docs/
    └── IMPLEMENTATION_NOTES.md         # Detailed technical, architectural, and bulk performance analysis
```

---

## 🚀 How to Run the Project

### Prerequisites
- Oracle Database (19c / 21c / 23c / 23ai)
- **Oracle SQL Developer** (Version 26.2.0.186.2220 or later) or **SQL*Plus**

### Execution Sequence in Oracle SQL Developer

#### Step 1: Open Oracle SQL Developer and Connect
1. Launch Oracle SQL Developer.
2. Connect to your database schema (e.g., `system` or your dedicated student schema).
3. Enable DBMS Output: Go to **View** -> **Dbms Output**, click the green **`+`** icon, and select your connection.

#### Step 2: Create Relational Schema
Open and execute:
```sql
@00_schema/01_create_tables.sql
```
*Creates all 7 tables with relationships, check constraints, default timestamps, and identity columns.*

#### Step 3: Insert Sample Seed Data
Open and execute:
```sql
@00_schema/02_insert_sample_data.sql
```
*Populates departments, courses (including INSY 8311), author student profiles (Arnold MUSAFIRI & Kevin INGABIRE), enrollments, and ledger transactions.*

#### Step 4: Compile Stored Functions
Compile the functions in `02_functions/` (order matters for dependencies):
1. `02_functions/fn_determine_letter_grade.sql`
2. `02_functions/fn_calculate_gpa.sql`
3. `02_functions/fn_get_student_summary.sql`

#### Step 5: Compile Stored Procedures
Compile the procedures in `01_procedures/`:
1. `01_procedures/sp_register_student_course.sql`
2. `01_procedures/sp_bulk_process_grades.sql`
3. `01_procedures/sp_update_tuition_balance.sql`

#### Step 6: Execute Success Test Cases
Open and run using **Run Script (F5)**:
```sql
@03_tests/test_success_cases.sql
```
*Verifies course enrollment, bulk grade calculation with audit logging, SQL-callable GPA computation, profile formatting, and tuition balance reconciliation.*

#### Step 7: Execute Error & Exception Handling Test Cases
Open and run using **Run Script (F5)**:
```sql
@03_tests/test_error_cases.sql
```
*Tests and verifies handling for duplicate enrollment (`DUP_VAL_ON_INDEX`), inactive courses, class capacity exhaustion, suspended students, out-of-range scores, non-existent records, and bulk failure logging.*

---

## 🎯 Technical Requirement Mapping

| Rubric Requirement | Where Implemented | Key PL/SQL Feature Demonstrated |
| :--- | :--- | :--- |
| **Records** | `sp_register_student_course.sql`<br>`fn_get_student_summary.sql` | • User-defined records (`t_registration_rec`, `t_student_profile_rec`)<br>• Table `%ROWTYPE` (`students%ROWTYPE`, `courses%ROWTYPE`) |
| **Collections** | `sp_bulk_process_grades.sql`<br>`fn_determine_letter_grade.sql` | • **Associative Array**: `INDEX BY VARCHAR2(5)` grade scale map<br>• **Nested Table**: `TABLE OF c_pending_enrollments%ROWTYPE`<br>• **VARRAY**: `VARRAY(2) OF NUMBER(3,2)` assessment weighting |
| **Implicit Cursors** | `sp_register_student_course.sql`<br>`sp_update_tuition_balance.sql` | Evaluates `SQL%ROWCOUNT`, `SQL%FOUND`, and `SQL%NOTFOUND` after `INSERT` and `UPDATE` statements |
| **Explicit Cursors** | `fn_calculate_gpa.sql`<br>`sp_update_tuition_balance.sql` | Full lifecycle: `OPEN`, `FETCH`, `CLOSE`, checking `%FOUND`, `%NOTFOUND`, `%ROWCOUNT` |
| **Bulk Processing** | `sp_bulk_process_grades.sql` | • `BULK COLLECT INTO ... LIMIT 100`<br>• `FORALL ... SAVE EXCEPTIONS`<br>• Traps `ORA-24381` and logs via `SQL%BULK_EXCEPTIONS` |
| **Stored Procedures** | `01_procedures/*.sql` | Includes `IN` and `OUT` parameters, status messaging, and transaction handling |
| **Functions** | `02_functions/*.sql` | Pure and SQL-callable functions returning GPA, letter grade, and formatted summaries |
| **Exception Handling** | Across all units & `03_tests/test_error_cases.sql` | `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `ZERO_DIVIDE`, `DUP_VAL_ON_INDEX`, custom exceptions, `RAISE_APPLICATION_ERROR`, `APPLICATION_ERROR_LOG` |

---

## 🤖 Academic Integrity & AI Statement

In accordance with AUCA academic integrity regulations:
- An AI assistant (Antigravity by Google DeepMind) was consulted during the preparation of this assignment to assist with modular project scaffolding, formatting Markdown documentation, and refining template syntax for `FORALL ... SAVE EXCEPTIONS` bulk processing.
- All database schema models, business workflow logic, constraints, grading calculations, and test scenarios were designed, verified, and executed by **MUSAFIRI Arnold** and **INGABIRE Kevin**.
- Both group members fully understand every procedure, function, cursor mechanism, collection, and exception handler contained in this repository and are prepared to defend and explain the code individually during class presentations.
