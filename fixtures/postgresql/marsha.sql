CREATE USER marsha WITH PASSWORD 'pass';
CREATE DATABASE marsha;
GRANT ALL PRIVILEGES ON DATABASE marsha TO marsha;
\connect marsha marsha;
CREATE TABLE IF NOT EXISTS video (
    id CHAR(36),
    title VARCHAR(255),
    PRIMARY KEY (id)
);
INSERT INTO video (id, title) VALUES ('69d32ad5-3af5-4160-a995-87e09da6865c', 'Video 1 Course 1');
INSERT INTO video (id, title) VALUES ('8d386f48-3baa-4acf-8a46-0f2be4ae243e', 'Video 2 Course 1');
INSERT INTO video (id, title) VALUES ('b172ec09-97ec-4651-bc57-6eabebf47ed0', 'Video 3 Course 1');
INSERT INTO video (id, title) VALUES ('d613b564-5d18-4238-a69c-0fc8cee5d0e7', 'Video 4 Course 1');
INSERT INTO video (id, title) VALUES ('e151ee65-7a72-478c-ac57-8a02f19e748b', 'Video 5 Course 1');
INSERT INTO video (id, title) VALUES ('0aecfa93-cef3-45ae-b7f5-a603e9e45f50', 'Video 1 Course 2');
INSERT INTO video (id, title) VALUES ('1c0c127a-f121-4bd1-8db6-918605c2645d', 'Video 2 Course 2');
INSERT INTO video (id, title) VALUES ('541dab6b-50ae-4444-b230-494f0621f132', 'Video 3 Course 2');
INSERT INTO video (id, title) VALUES ('7d4f3c70-1e79-4243-9b7d-166076ce8bfb', 'Video 4 Course 2');
INSERT INTO video (id, title) VALUES ('dd38149d-956a-483d-8975-c1506de1e1a9', 'Video 5 Course 2');
