CREATE TABLE sql_catalog (
	label varchar(32) ,
	tables varchar(255) ,
	columns varchar(255) ,
	cmd varchar(40) ,
	phold int4,
	query varchar(65535) ,
	CONSTRAINT sql_catalog_pkey PRIMARY KEY (label)
);
