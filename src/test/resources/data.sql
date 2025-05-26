---------  users ----------------------
DELETE
FROM USER_ROLE;
DELETE
FROM CONTACT;
DELETE
FROM PROFILE;

DELETE
FROM ACTIVITY;
CREATE
    SEQUENCE IF NOT EXISTS ACTIVITY_ID_SEQ;
ALTER
    SEQUENCE ACTIVITY_ID_SEQ RESTART WITH 1;

CREATE
    SEQUENCE IF NOT EXISTS TASK_ID_SEQ;
CREATE
    SEQUENCE IF NOT EXISTS SPRINT_ID_SEQ;
CREATE
    SEQUENCE IF NOT EXISTS PROJECT_ID_SEQ;
CREATE
    SEQUENCE IF NOT EXISTS USERS_ID_SEQ;

DELETE
FROM TASK;
ALTER
    SEQUENCE TASK_ID_SEQ RESTART WITH 1;

DELETE
FROM SPRINT;
ALTER
    SEQUENCE SPRINT_ID_SEQ RESTART WITH 1;

DELETE
FROM PROJECT;
ALTER
    SEQUENCE PROJECT_ID_SEQ RESTART WITH 1;

DELETE
FROM USERS;
ALTER
    SEQUENCE USERS_ID_SEQ RESTART WITH 1;


INSERT INTO USERS (EMAIL, PASSWORD, FIRST_NAME, LAST_NAME, DISPLAY_NAME, startpoint)
VALUES ('user@gmail.com', '{noop}password', 'userFirstName', 'userLastName', 'userDisplayName','2025-05-10 22:52:04.836350'),
       ('admin@gmail.com', '{noop}admin', 'adminFirstName', 'adminLastName', 'adminDisplayName','2025-05-10 22:52:04.836350'),
       ('guest@gmail.com', '{noop}guest', 'guestFirstName', 'guestLastName', 'guestDisplayName','2025-05-10 22:52:04.836350'),
       ('manager@gmail.com', '{noop}manager', 'managerFirstName', 'managerLastName', 'managerDisplayName','2025-05-10 22:52:04.836350');

-- 0 DEV
-- 1 ADMIN
-- 2 MANAGER

INSERT INTO USER_ROLE (USER_ID, ROLE)
VALUES (1, 0),
       (2, 0),
       (2, 1),
       (4, 2);

INSERT INTO PROFILE (ID, LAST_FAILED_LOGIN, LAST_LOGIN, MAIL_NOTIFICATIONS)
VALUES (1, NULL, NULL, 49),
       (2, NULL, NULL, 14);

INSERT INTO CONTACT (ID, CODE, CONTACT_VALUE)
VALUES (1, 'skype', 'userSkype'),
       (1, 'mobile', '+01234567890'),
       (1, 'website', 'user.com'),
       (2, 'github', 'adminGitHub'),
       (2, 'tg', 'adminTg'),
       (2, 'vk', 'adminVk');


INSERT INTO PROJECT (code, title, description, type_code, parent_id,startpoint)
VALUES ('PR1', 'PROJECT-1', 'test project 1', 'task_tracker', NULL,'2025-05-10 22:52:04.836350'),
       ('PR2', 'PROJECT-2', 'test project 2', 'task_tracker', 1,'2025-05-10 22:52:04.836350');

INSERT INTO SPRINT (status_code, startpoint, endpoint, code, project_id)
VALUES ('finished', '2023-05-01 08:05:10', '2023-05-07 17:10:01', 'SP-1.001', 1),
       ('active', '2023-05-01 08:06:00', NULL, 'SP-1.002', 1),
       ('active', '2023-05-01 08:07:00', NULL, 'SP-1.003', 1),
       ('planning', '2023-05-01 08:08:00', NULL, 'SP-1.004', 1),
       ('active', '2023-05-10 08:06:00', NULL, 'SP-2.001', 2),
       ('planning', '2023-05-10 08:07:00', NULL, 'SP-2.002', 2),
       ('planning', '2023-05-10 08:08:00', NULL, 'SP-2.003', 2);

INSERT INTO TASK (TITLE, TYPE_CODE, STATUS_CODE, PROJECT_ID, SPRINT_ID, STARTPOINT)
VALUES ('Data', 'epic', 'in_progress', 1, 1, '2023-05-15 09:05:10'),
       ('Trees', 'epic', 'in_progress', 1, 1, '2023-05-15 12:05:10'),
       ('task-3', 'task', 'ready_for_test', 2, 5, '2023-06-14 09:28:10'),
       ('task-4', 'task', 'ready_for_review', 2, 5, '2023-06-14 09:28:10'),
       ('task-5', 'task', 'todo', 2, 5, '2023-06-14 09:28:10'),
       ('task-6', 'task', 'done', 2, 5, '2023-06-14 09:28:10'),
       ('task-7', 'task', 'canceled', 2, 5, '2023-06-14 09:28:10');


INSERT INTO ACTIVITY(AUTHOR_ID, TASK_ID, UPDATED, COMMENT, TITLE, DESCRIPTION, ESTIMATE, TYPE_CODE, STATUS_CODE,
                     PRIORITY_CODE)
VALUES (1, 1, '2023-05-15 09:05:10', NULL, 'Data', NULL, 3, 'epic', 'in_progress', 'low'),
       (2, 1, '2023-05-15 12:25:10', NULL, 'Data', NULL, NULL, NULL, NULL, 'normal'),
       (1, 1, '2023-05-15 14:05:10', NULL, 'Data', NULL, 4, NULL, NULL, NULL),
       (1, 2, '2023-05-15 12:05:10', NULL, 'Trees', 'Trees desc', 4, 'epic', 'in_progress', 'normal');

INSERT INTO USER_BELONG (OBJECT_ID, OBJECT_TYPE, USER_ID, USER_TYPE_CODE, STARTPOINT, ENDPOINT)
VALUES (1, 2, 2, 'task_developer', '2023-06-14 08:35:10', '2023-06-14 08:55:00'),
       (1, 2, 2, 'task_reviewer', '2023-06-14 09:35:10', NULL),
       (1, 2, 1, 'task_developer', '2023-06-12 11:40:00', '2023-06-12 12:35:00'),
       (1, 2, 1, 'task_developer', '2023-06-13 12:35:00', NULL),
       (1, 2, 1, 'task_tester', '2023-06-14 15:20:00', NULL),
       (2, 2, 2, 'task_developer', '2023-06-08 07:10:00', NULL),
       (2, 2, 1, 'task_developer', '2023-06-09 14:48:00', NULL),
       (2, 2, 1, 'task_tester', '2023-06-10 16:37:00', NULL);