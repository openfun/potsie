CREATE TABLE IF NOT EXISTS courses_course (
    id INT PRIMARY KEY NOT NULL,
    `key` VARCHAR(255)
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
INSERT INTO courses_course (id, `key`) VALUES (1, 'course-v1:FUN-MOOC+00001+session01');
INSERT INTO courses_course (id, `key`) VALUES (2, 'course-v1:FUN-MOOC+00002+session01');
INSERT INTO student_courseaccessrole (id, `user_id`, `course_id`, role) VALUES (1, 1, 'course-v1:FUN-MOOC+00001+session01', 'staff');
INSERT INTO student_courseaccessrole (id, `user_id`, `course_id`, role) VALUES (2, 1, 'course-v1:FUN-MOOC+00002+session01', 'instructor');
INSERT INTO auth_user (id, email, username) VALUES (1, 'teacher@example.org', 'teacher');
INSERT INTO auth_user (id, email, username) VALUES (2, 'student@example.org', 'student');
