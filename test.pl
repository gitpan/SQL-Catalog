# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use SQL::Catalog;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $dbh = SQL::Catalog->db_handle;
my $sql = SQL::Catalog->lookup('basic_weather');
my $sth = $dbh->prepare($sql);
$sth->execute(55);

my $rows = $sth->rows;

$sth->finish;
$dbh->disconnect;

warn "rows returned ", $rows;

$rows > 0 and print "ok 2" and exit;

print "nok 2";


