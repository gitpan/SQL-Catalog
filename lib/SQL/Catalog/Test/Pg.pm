package SQL::Catalog::Test::Pg;

use DBI;

sub create_sql_catalog {

    my $self = shift;

    use Data::Dumper;
    warn "createsql: ", Dumper($self);

    $self->{dbh}->do(<<EOD);
CREATE TABLE sql_catalog (
	label varchar(80) NOT NULL,
	cmd varchar(40) NOT NULL,
	phold int4 NOT NULL,
	author varchar(40) NOT NULL,
	query varchar(65536) NOT NULL,
	comments varchar(1600) NOT NULL,
	PRIMARY KEY (label)
);

CREATE TABLE sql_catalog_ft (
	label_ft varchar(80) NOT NULL,
	tbl varchar(255) NOT NULL,
	col varchar(255) NOT NULL
);

EOD

}

1;
