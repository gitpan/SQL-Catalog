CREATE TABLE sql_catalog (
	label varchar(80) NOT NULL,
	cmd varchar(40) NOT NULL,
	phold int4 NOT NULL,
	author varchar(40) NOT NULL,
	query varchar(65536) NOT NULL,
	comments varchar(1600) NOT NULL,
	PRIMARY KEY (label)
);
CREATE INDEX sql_catalog__idx ON sql_catalog (label);
CREATE TABLE sql_catalog_ft (
	label_ft varchar(80) NOT NULL,
	tbl varchar(255) NOT NULL,
	col varchar(255) NOT NULL,
	PRIMARY KEY (label_ft)
);
CREATE INDEX sql_catalog_ft__idx ON sql_catalog_ft (label_ft);
