CREATE TABLE sql_catalog
(
    label VARCHAR(32),
    query CHAR(30000),
    tables VARCHAR(255),
    columns VARCHAR(255),
    cmd VARCHAR(40),
    phold INTEGER,
    PRIMARY KEY (label)
);
