--liquibase formatted SQL

--changeset kmpk:init_schema
DROP TABLE IF EXISTS USER_ROLE;
DROP TABLE IF EXISTS CONTACT;
DROP TABLE IF EXISTS MAIL_CASE;
DROP
    SEQUENCE IF EXISTS MAIL_CASE_ID_SEQ;
DROP TABLE IF EXISTS PROFILE;
DROP TABLE IF EXISTS TASK_TAG;
DROP TABLE IF EXISTS USER_BELONG;
DROP
    SEQUENCE IF EXISTS USER_BELONG_ID_SEQ;
DROP TABLE IF EXISTS ACTIVITY;
DROP
    SEQUENCE IF EXISTS ACTIVITY_ID_SEQ;
DROP TABLE IF EXISTS TASK;
DROP
    SEQUENCE IF EXISTS TASK_ID_SEQ;
DROP TABLE IF EXISTS SPRINT;
DROP
    SEQUENCE IF EXISTS SPRINT_ID_SEQ;
DROP TABLE IF EXISTS PROJECT;
DROP
    SEQUENCE IF EXISTS PROJECT_ID_SEQ;
DROP TABLE IF EXISTS REFERENCE;
DROP
    SEQUENCE IF EXISTS REFERENCE_ID_SEQ;
DROP TABLE IF EXISTS ATTACHMENT;
DROP
    SEQUENCE IF EXISTS ATTACHMENT_ID_SEQ;
DROP TABLE IF EXISTS USERS;
DROP
    SEQUENCE IF EXISTS USERS_ID_SEQ;

CREATE TABLE PROJECT
(
    ID bigserial PRIMARY KEY,
    CODE        varchar(32)   NOT NULL CONSTRAINT UK_PROJECT_CODE UNIQUE,
    TITLE       varchar(1024) NOT NULL,
    DESCRIPTION varchar(4096) NOT NULL,
    TYPE_CODE   varchar(32)   NOT NULL,
    STARTPOINT  timestamp,
    ENDPOINT    timestamp,
    PARENT_ID   bigint,
    CONSTRAINT FK_PROJECT_PARENT FOREIGN KEY (PARENT_ID) REFERENCES PROJECT (ID) ON DELETE CASCADE
);

CREATE TABLE MAIL_CASE
(
    ID bigserial PRIMARY KEY,
    EMAIL     varchar(255) NOT NULL,
    NAME      varchar(255) NOT NULL,
    DATE_TIME timestamp    NOT NULL,
    RESULT    varchar(255) NOT NULL,
    TEMPLATE  varchar(255) NOT NULL
);

CREATE TABLE SPRINT
(
    ID bigserial PRIMARY KEY,
    STATUS_CODE varchar(32)   NOT NULL,
    STARTPOINT  timestamp,
    ENDPOINT    timestamp,
    TITLE       varchar(1024) NOT NULL,
    PROJECT_ID  bigint        NOT NULL,
    CONSTRAINT FK_SPRINT_PROJECT FOREIGN KEY (PROJECT_ID) REFERENCES PROJECT (ID) ON DELETE CASCADE
);

CREATE TABLE REFERENCE
(
    ID bigserial PRIMARY KEY,
    CODE       varchar(32)   NOT NULL,
    REF_TYPE   smallint      NOT NULL,
    ENDPOINT   timestamp,
    STARTPOINT timestamp,
    TITLE      varchar(1024) NOT NULL,
    AUX        varchar,
    CONSTRAINT UK_REFERENCE_REF_TYPE_CODE UNIQUE (REF_TYPE, CODE)
);

CREATE TABLE USERS
(
    ID bigserial PRIMARY KEY,
    DISPLAY_NAME varchar(32)  NOT NULL CONSTRAINT UK_USERS_DISPLAY_NAME UNIQUE,
    EMAIL        varchar(128) NOT NULL CONSTRAINT UK_USERS_EMAIL UNIQUE,
    FIRST_NAME   varchar(32)  NOT NULL,
    LAST_NAME    varchar(32),
    PASSWORD     varchar(128) NOT NULL,
    ENDPOINT     timestamp,
    STARTPOINT   timestamp NULL
);

CREATE TABLE PROFILE
(
    ID                 bigint PRIMARY KEY,
    LAST_LOGIN         timestamp,
    LAST_FAILED_LOGIN  timestamp,
    MAIL_NOTIFICATIONS bigint,
    CONSTRAINT FK_PROFILE_USERS FOREIGN KEY (ID) REFERENCES USERS (ID) ON DELETE CASCADE
);

CREATE TABLE CONTACT
(
    ID            bigint       NOT NULL,
    CODE          varchar(32)  NOT NULL,
    CONTACT_VALUE varchar(256) NOT NULL,
    PRIMARY KEY (ID, CODE),
    CONSTRAINT FK_CONTACT_PROFILE FOREIGN KEY (ID) REFERENCES PROFILE (ID) ON DELETE CASCADE
);

CREATE TABLE TASK
(
    ID bigserial PRIMARY KEY,
    TITLE         varchar(1024) NOT NULL,
    DESCRIPTION   varchar(4096) NOT NULL,
    TYPE_CODE     varchar(32)   NOT NULL,
    STATUS_CODE   varchar(32)   NOT NULL,
    PRIORITY_CODE varchar(32)   NOT NULL,
    ESTIMATE      integer,
    UPDATED       timestamp,
    PROJECT_ID    bigint        NOT NULL,
    SPRINT_ID     bigint,
    PARENT_ID     bigint,
    STARTPOINT    timestamp,
    ENDPOINT      timestamp,
    CONSTRAINT FK_TASK_SPRINT FOREIGN KEY (SPRINT_ID) REFERENCES SPRINT (ID) ON DELETE SET NULL,
    CONSTRAINT FK_TASK_PROJECT FOREIGN KEY (PROJECT_ID) REFERENCES PROJECT (ID) ON DELETE CASCADE,
    CONSTRAINT FK_TASK_PARENT_TASK FOREIGN KEY (PARENT_ID) REFERENCES TASK (ID) ON DELETE CASCADE
);

CREATE TABLE ACTIVITY
(
    ID bigserial PRIMARY KEY,
    AUTHOR_ID     bigint NOT NULL,
    TASK_ID       bigint NOT NULL,
    UPDATED       timestamp,
    COMMENT       varchar(4096),
--     history of task field change
    TITLE         varchar(1024),
    DESCRIPTION   varchar(4096),
    ESTIMATE      integer,
    TYPE_CODE     varchar(32),
    STATUS_CODE   varchar(32),
    PRIORITY_CODE varchar(32),
    CONSTRAINT FK_ACTIVITY_USERS FOREIGN KEY (AUTHOR_ID) REFERENCES USERS (ID),
    CONSTRAINT FK_ACTIVITY_TASK FOREIGN KEY (TASK_ID) REFERENCES TASK (ID) ON DELETE CASCADE
);

CREATE TABLE TASK_TAG
(
    TASK_ID bigint      NOT NULL,
    TAG     varchar(32) NOT NULL,
    CONSTRAINT UK_TASK_TAG UNIQUE (TASK_ID, TAG),
    CONSTRAINT FK_TASK_TAG FOREIGN KEY (TASK_ID) REFERENCES TASK (ID) ON DELETE CASCADE
);

CREATE TABLE USER_BELONG
(
    ID bigserial PRIMARY KEY,
    OBJECT_ID      bigint      NOT NULL,
    OBJECT_TYPE    smallint    NOT NULL,
    USER_ID        bigint      NOT NULL,
    USER_TYPE_CODE varchar(32) NOT NULL,
    STARTPOINT     timestamp,
    ENDPOINT       timestamp,
    CONSTRAINT FK_USER_BELONG FOREIGN KEY (USER_ID) REFERENCES USERS (ID)
);
CREATE UNIQUE INDEX UK_USER_BELONG ON USER_BELONG (OBJECT_ID, OBJECT_TYPE, USER_ID, USER_TYPE_CODE);
CREATE INDEX IX_USER_BELONG_USER_ID ON USER_BELONG (USER_ID);

CREATE TABLE ATTACHMENT
(
    ID bigserial PRIMARY KEY,
    NAME        varchar(128)  NOT NULL,
    FILE_LINK   varchar(2048) NOT NULL,
    OBJECT_ID   bigint        NOT NULL,
    OBJECT_TYPE smallint      NOT NULL,
    USER_ID     bigint        NOT NULL,
    DATE_TIME   timestamp,
    CONSTRAINT FK_ATTACHMENT FOREIGN KEY (USER_ID) REFERENCES USERS (ID)
);

CREATE TABLE USER_ROLE
(
    USER_ID bigint   NOT NULL,
    ROLE    smallint NOT NULL,
    CONSTRAINT UK_USER_ROLE UNIQUE (USER_ID, ROLE),
    CONSTRAINT FK_USER_ROLE FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE
);

--changeset kmpk:populate_data
--============ REFERENCES =================
INSERT INTO REFERENCE (CODE, TITLE, REF_TYPE)
-- TASK
VALUES ('task', 'Task', 2),
       ('story', 'Story', 2),
       ('bug', 'Bug', 2),
       ('epic', 'Epic', 2),
-- SPRINT_STATUS
       ('planning', 'Planning', 4),
       ('active', 'Active', 4),
       ('finished', 'Finished', 4),
-- USER_TYPE
       ('author', 'Author', 5),
       ('developer', 'Developer', 5),
       ('reviewer', 'Reviewer', 5),
       ('tester', 'Tester', 5),
-- PROJECT
       ('scrum', 'Scrum', 1),
       ('task_tracker', 'Task tracker', 1),
-- CONTACT
       ('skype', 'Skype', 0),
       ('tg', 'Telegram', 0),
       ('mobile', 'Mobile', 0),
       ('phone', 'Phone', 0),
       ('website', 'Website', 0),
       ('vk', 'VK', 0),
       ('linkedin', 'LinkedIn', 0),
       ('github', 'GitHub', 0),
-- PRIORITY
       ('critical', 'Critical', 7),
       ('high', 'High', 7),
       ('normal', 'Normal', 7),
       ('low', 'Low', 7),
       ('neutral', 'Neutral', 7);

INSERT INTO REFERENCE (CODE, TITLE, REF_TYPE, AUX)
-- MAIL_NOTIFICATION
VALUES ('assigned', 'Assigned', 6, '1'),
       ('three_days_before_deadline', 'Three days before deadline', 6, '2'),
       ('two_days_before_deadline', 'Two days before deadline', 6, '4'),
       ('one_day_before_deadline', 'One day before deadline', 6, '8'),
       ('deadline', 'Deadline', 6, '16'),
       ('overdue', 'Overdue', 6, '32'),
-- TASK_STATUS
       ('todo', 'ToDo', 3, 'in_progress,canceled'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled'),
       ('ready_for_review', 'Ready for review', 3, 'review,canceled'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled'),
       ('ready_for_test', 'Ready for test', 3, 'test,canceled'),
       ('test', 'Test', 3, 'done,in_progress,canceled'),
       ('done', 'Done', 3, 'canceled'),
       ('canceled', 'Canceled', 3, NULL);

--changeset gkislin:change_backtracking_tables

ALTER TABLE SPRINT RENAME COLUMN TITLE TO CODE;
ALTER TABLE SPRINT
    ALTER COLUMN CODE TYPE VARCHAR (32);
ALTER TABLE SPRINT
    ALTER COLUMN CODE SET NOT NULL;
CREATE UNIQUE INDEX UK_SPRINT_PROJECT_CODE ON SPRINT (PROJECT_ID, CODE);

ALTER TABLE TASK
    DROP COLUMN DESCRIPTION;
ALTER TABLE TASK
    DROP COLUMN PRIORITY_CODE;
ALTER TABLE TASK
    DROP COLUMN ESTIMATE;
ALTER TABLE TASK
    DROP COLUMN UPDATED;

--changeset ishlyakhtenkov:change_task_status_reference

DELETE
FROM REFERENCE
WHERE REF_TYPE = 3;
INSERT INTO REFERENCE (CODE, TITLE, REF_TYPE, AUX)
VALUES ('todo', 'ToDo', 3, 'in_progress,canceled'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled'),
       ('ready_for_review', 'Ready for review', 3, 'in_progress,review,canceled'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled'),
       ('ready_for_test', 'Ready for test', 3, 'review,test,canceled'),
       ('test', 'Test', 3, 'done,in_progress,canceled'),
       ('done', 'Done', 3, 'canceled'),
       ('canceled', 'Canceled', 3, NULL);

--changeset gkislin:users_add_on_delete_cascade

ALTER TABLE ACTIVITY
    DROP CONSTRAINT IF EXISTS FK_ACTIVITY_USERS;
ALTER TABLE ACTIVITY
    ADD CONSTRAINT FK_ACTIVITY_USERS
        FOREIGN KEY (AUTHOR_ID) REFERENCES USERS (ID) ON DELETE CASCADE;

ALTER TABLE USER_BELONG
    DROP CONSTRAINT IF EXISTS FK_USER_BELONG;
ALTER TABLE USER_BELONG
    ADD CONSTRAINT FK_USER_BELONG
        FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE;

ALTER TABLE ATTACHMENT
    DROP CONSTRAINT IF EXISTS FK_ATTACHMENT;
ALTER TABLE ATTACHMENT
    ADD CONSTRAINT FK_ATTACHMENT
        FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE;


--changeset valeriyemelyanov:change_user_type_reference

DELETE
FROM REFERENCE
WHERE REF_TYPE = 5;
INSERT INTO REFERENCE (CODE, TITLE, REF_TYPE)
-- USER_TYPE
VALUES ('project_author', 'Author', 5),
       ('project_manager', 'Manager', 5),
       ('sprint_author', 'Author', 5),
       ('sprint_manager', 'Manager', 5),
       ('task_author', 'Author', 5),
       ('task_developer', 'Developer', 5),
       ('task_reviewer', 'Reviewer', 5),
       ('task_tester', 'Tester', 5);

--changeset apolik:refactor_reference_aux

-- TASK_TYPE
DELETE
FROM REFERENCE
WHERE REF_TYPE = 3;
INSERT INTO REFERENCE (CODE, TITLE, REF_TYPE, AUX)
VALUES ('todo', 'ToDo', 3, 'in_progress,canceled|'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled|task_developer'),
       ('ready_for_review', 'Ready for review', 3, 'in_progress,review,canceled|'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled|task_reviewer'),
       ('ready_for_test', 'Ready for test', 3, 'review,test,canceled|'),
       ('test', 'Test', 3, 'done,in_progress,canceled|task_tester'),
       ('done', 'Done', 3, 'canceled|'),
       ('canceled', 'Canceled', 3, NULL);

--changeset ishlyakhtenkov:change_UK_USER_BELONG

DROP INDEX UK_USER_BELONG;
CREATE UNIQUE INDEX UK_USER_BELONG
    ON USER_BELONG (OBJECT_ID, OBJECT_TYPE, USER_ID, USER_TYPE_CODE, ENDPOINT);