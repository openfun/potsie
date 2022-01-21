CREATE TABLE IF NOT EXISTS courses_course (
    id INT PRIMARY KEY NOT NULL,
    `key` VARCHAR(255),
    `title` VARCHAR(255),
    `start_date` DATE,
    `end_date` DATE
);
CREATE TABLE IF NOT EXISTS student_courseaccessrole (
    id INT PRIMARY KEY NOT NULL,
    `user_id` INT,
    `course_id` VARCHAR(255),
    `role` VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS auth_user (
    id INT PRIMARY KEY NOT NULL,
    email NVARCHAR(255),
    username VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS student_courseenrollment (
    id INT PRIMARY KEY NOT NULL,
    `user_id` INT,
    `course_id` VARCHAR(255),
    `is_active` INT
);
INSERT INTO courses_course (id, `key`, `title`, `start_date`, `end_date`) VALUES (1, 'course-v1:FUN-MOOC+00001+session01', 'FUN Mooc Course 1 Session 1', DATE('2000-01-01'), DATE('2030-01-01'));
INSERT INTO courses_course (id, `key`, `title`, `start_date`, `end_date`) VALUES (2, 'course-v1:FUN-MOOC+00002+session01', 'FUN Mooc Course 2 Session 2', DATE('2000-01-01'), DATE('2030-01-01'));
INSERT INTO student_courseaccessrole (id, `user_id`, `course_id`, `role`) VALUES (1, 1, 'course-v1:FUN-MOOC+00001+session01', 'staff');
INSERT INTO student_courseaccessrole (id, `user_id`, `course_id`, `role`) VALUES (2, 1, 'course-v1:FUN-MOOC+00002+session01', 'instructor');
INSERT INTO auth_user (id, email, username) VALUES (1, 'teacher@example.org', 'teacher');
INSERT INTO auth_user (id, email, username) VALUES (2, 'student@example.org', 'student');
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (1, 23, 'course-v1:FUN-MOOC+00001+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (2, 65, 'course-v1:FUN-MOOC+00001+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (3, 7, 'course-v1:FUN-MOOC+00001+session01', 0);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (4, 90, 'course-v1:FUN-MOOC+00001+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (5, 18, 'course-v1:FUN-MOOC+00002+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (6, 5, 'course-v1:FUN-MOOC+00002+session01', 0);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (7, 71, 'course-v1:FUN-MOOC+00002+session01', 0);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (8, 764, 'course-v1:FUN-MOOC+00002+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (9, 2, 'course-v1:FUN-MOOC+00001+session01', 1);
INSERT INTO student_courseenrollment (id, `user_id`, `course_id`, `is_active`) VALUES (10, 2, 'course-v1:FUN-MOOC+00002+session01', 1);
