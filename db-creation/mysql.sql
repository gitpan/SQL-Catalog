CREATE TABLE sql_catalog (
            label varchar(80) not null,
            cmd varchar(40) ,
            phold int4 ,
            author varchar(40) ,
            query text,
            comments text,
            PRIMARY KEY (label)
                              );

CREATE TABLE sql_catalog_ft (
            label_ft varchar(80) not null,
            tbl varchar(255) ,
            col varchar(255) ,
            PRIMARY KEY (label_ft)
                                 );