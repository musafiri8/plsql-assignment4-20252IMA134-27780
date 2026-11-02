# Screenshots Directory

This directory stores visual evidence and execution outputs from **Oracle SQL Developer (Version 26.2.0.186.2220)** as required by the assignment guidelines.

### Expected Screenshot Files

| File Name | Description |
| :--- | :--- |
| `01_tables_created_output.png` | Script Output pane after running `00_schema/01_create_tables.sql` |
| `02_sample_data_output.png` | Script Output pane after running `00_schema/02_insert_sample_data.sql` |
| `03_procedures_compiled_output.png` | Compiler log showing `sp_register_student_course`, `sp_bulk_process_grades`, and `sp_update_tuition_balance` compiled without errors |
| `04_functions_compiled_output.png` | Compiler log showing `fn_determine_letter_grade`, `fn_calculate_gpa`, and `fn_get_student_summary` compiled without errors |
| `05_test_success_output.png` | Script Output pane after running `03_tests/test_success_cases.sql` |
| `06_test_error_output.png` | Script Output pane after running `03_tests/test_error_cases.sql` showing exception captures |
| `07_audit_log_verification.png` | Data grid showing rows inserted into `GRADE_AUDIT_LOG` and `APPLICATION_ERROR_LOG` |

### How to Capture from Oracle SQL Developer
1. In Oracle SQL Developer, open each script file.
2. Ensure DBMS Output is enabled (`View` -> `Dbms Output` -> click the green **`+`** icon to attach your connection).
3. Execute the script using **Run Script (F5)**.
4. Capture the Script Output / DBMS Output window using `Win + Shift + S` or the Snipping Tool.
5. Save the image directly in this `screenshots/` directory with the filenames listed above.
