use strict;
use Test;

BEGIN { plan tests => 2 }


ok(1,1);

use Data::Dumper;

use SQL::Catalog::Config;
use SQL::Catalog::Test;

my %param = %SQL::Catalog::Config::param;

my $result;
for (keys %param) {
  SQL::Catalog::Test->set_dsn ($param{$_}->{DataSource});
  SQL::Catalog::Test->set_user($param{$_}->{UserName});
  SQL::Catalog::Test->set_password($param{$_}->{Password});
    my $dbh = SQL::Catalog::Test->instance;
    $result = $dbh->create_sql_catalog;
}


ok($result);
