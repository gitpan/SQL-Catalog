package SQL::Catalog;

use DBI;
use SQL::Statement;
use Data::Dumper;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.03';


# Preloaded methods go here.
sub load_sql_from {
    my $file = shift;
    open A, $file or die "cannot open $file";
    join '', <A>;
}

sub db_handle {

    my $connect  = $ENV{SQL_CATALOG_DSN};
    my $username = $ENV{SQL_CATALOG_USR};
    my $password = $ENV{SQL_CATALOG_PAS};

    DBI->connect($connect, $username, $password,
		 { RaiseError => 1, PrintError => 1 });

}

sub parse_sql {

    my $sql= shift;

  # Create a parse
   my($parser) = SQL::Parser->new('Ansi');

   # Parse an SQL statement
   $@ = '';
   my ($stmt) = eval {
     SQL::Statement->new($sql, $parser);
   };
   if ($@) {
       die "Cannot parse statement: $@";
   }

    my %pa;

    # Query the list of result columns;
    my @columns = $stmt->columns;    # Array context
    $pa{columns}= \@columns;
    
    # Likewise, query the tables being used in the statement:
    my @tables = $stmt->tables;      # Array context
    $pa{tables}= \@tables;

    my $params = $stmt->params;
    $pa{params}= $params;

    my $command = $stmt->command;
    $pa{command}= $command;

    \%pa;
}

sub register {

    my ($class,$file,$label) = @_;

    my $sql = load_sql_from $file;

   die "you must create a label for this SQL: $sql" unless $label;
 
    my $parse = parse_sql $sql;

    my $tables = join ',', map { $_->{table} } @{$parse->{tables}};
    my $columns = 
	join ',', 
	map { $_->{table} . '.' . $_->{column} } @{$parse->{columns}};

   #   die Dumper(\@columns, \@tables, $params, \$command);
 
   my $insert='insert into sql_catalog
       (label,  query,  tables, columns, cmd, phold)
values (  ?  ,   ?   ,    ?   ,    ?   ,  ? ,   ?  )';
    
   my $dbh = db_handle;

#   warn $insert;
#   warn "$label, $sql, $tables, $columns, $command, $params";

   my $sth = $dbh->prepare($insert);

   $sth->execute
       ($label, $sql, 
	$tables, $columns, $parse->{command}, $parse->{params});

    print "[$label] inserted as\n[$sql]";

    $dbh->disconnect;
   
}

sub lookup {

    my ($class,$label) = @_;

    defined $label or die "must supply label";

    warn "looking for label [$label]";

    my $dbh = db_handle;

    my $lookup = 'select query from sql_catalog where label = ?';
    my $sth = $dbh->prepare($lookup);

    $sth->execute($label);

    my $rows = $sth->rows;
    $rows == 1 or die "error. lookup query returned $rows instead of 1";

    my $row = $sth->fetchrow_hashref;

    $row->{query};

}

sub test {
    warn "NO PLACEHOLDER VALUES SUPPLIED" unless @_;
    my ($class,$file,@bind_args) = @_;
    my $sql = load_sql_from $file;

    my $parse = parse_sql $sql;


    my $dbh = db_handle;
    my $sth = $dbh->prepare($sql);
    
    $sth->execute(@bind_args);

    use Data::Dumper;

    return unless ($parse->{command} =~ /select/i);


    open T, '>testexec.out' or die 'cannot create output file';
    print T "Query
$sql

";

    print T "Bind Values
@ARGV

";

    printf T "Results (%d rows)\n", $sth->rows;

    while (my $rec = $sth->fetchrow_hashref) {
	print Dumper($rec);
	print T Dumper($rec);
    }


    $dbh->disconnect;

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

SQL::Catalog - test, label, store, search and retrieve SQL queries

=head1 SYNOPSIS

 shell% cd sql_lair/city,date/weather/1/

 shell% cat concrete.sql 
 select city, date from weather where temp_lo < 20;
 shell% sql_test concrete.sql 
 shell% cat testexec.out # see results of prepare, execute on this

 shell% cat abstract.sql
 select city, date from weather where temp_lo < ?;
 shell% sql_test abstract.sql 55 # send in placeholder value
 shell% cat testexec.out # to see results... looks good

 shell% sql_register abstract.sql basic_weather
 [hi_and_low] inserted as 
 [select city from weather where temp_lo > ? and temp_hi > ? LIMIT 10]

 ... then in a Perl program (e.g. test.pl in this distribution)
 my $dbh = SQL::Catalog->db_handle; # optional - get the handle as you please
 my $sql = SQL::Catalog->lookup('hi_and_low');
 my $sth = $dbh->prepare($sql);
 $sth->execute(55);

 my $rows = $sth->rows;


=head1 DESCRIPTION

Over time, it has become obvious that a few things about SQL queries are 
necessary. One, you want to be able to get a query by a label. Two, you want 
to be able to look through old queries to see if someone else has written
one similar to what you want. Three, you want the database guru to develop
queries on his own and be able to register them for your use without 
interfering with him. Four, you want to be able to answer questions such as
"what queries are doing a select on such-and-such tables".

Well, wait no longer, for your solution has arrived.

=head1 COMMON STEPS TO USAGE

=head2 Develop your concrete query in a db shell

The first step to developing a database query is to play around at the 
db shell. In this case, you normally dont have any placeheld values. You just
keep mucking with the query until it gives you what you want.

When you finally get what you want, save it in a file, say C<concrete.sql> for 
example. Here is a concrete query:

 select city, date from weather where temp_hi > 20

=head2 Abstract your query with placeholders

Now it's time to make your query more abstract. So we do the following:

 select city, date from weather where temp_hi > ? 

and save in a different file, say C<abstract.sql>.

Now let's test this query also, being sure to pass in data for the 
placeholder fields:

 sql_test abstract.sql 34

Certain drivers are not very good with their error messages in response to
queries sent in without placeholder bindings, so take care here.

And let's cat testexec.out to see the results.

=head2 Register your query (store in the sql_category table)

 sql_register abstract.sql city_date_via_temp_hi

and the system tells you

 [city_date_via_temp_hi] saved as
 [select city, date from weather where temp_hi > ?] 

=head2 Use your query from DBI:

 use SQL::Catalog;

 my $dbh = SQL::Catalog->db_handle; # or however you get your DBI handles
 my $SQL = SQL::Catalog->lookup('city_date_via_temp_hi') or die "not found";
 my $sth = $dbh->prepare($SQL, $cgi->param('degrees'));
  .... etc

=head1 INSTALLATION

See the README in the home directory of the distribution.

=head1 What SQL::Catalog does

It stores each query in a database table. I could have gone for
something more normalized and exquisite in database design but wanted to 
maintain 
database independence without requiring extra tools for schema
creation and database use. 

Right now we have schema creation and SQL code which works for Informix and
Postgresql and welcome more.

The queries are stored in this table 
(this file is C<db-creation/postgresql.sql>):

 CREATE TABLE sql_catalog (
        label varchar(32) ,  # the label queries are stored and looked up with
        tables varchar(255) , # the tables used in the query
        columns varchar(255) , # the columns used in the query
        cmd varchar(40) , # type of sql (SELECT, INSERT, UPDATE, etc)
        phold int4,  # number of placeholders in the query
        query varchar(65535) , # the query to be stored
        CONSTRAINT sql_catalog_pkey PRIMARY KEY (label) # indexing
 );

Query field omitted for brevity. It has (wouldya guess) the SQL query.

  mydb=# select label,cmd,columns,tables,phold from sql_catalog;
      label     |  cmd   | columns                          | tables  | phold 
 ---------------+--------+---------------------------------------------------
 weather_hi    | SELECT | weather.city,weather.date        | weather |     1
 hi_and_low    | SELECT | weather.city                     | weather |     2

=head1 NOTES

=over 4

=item * Read the README for thorough install instructions for various
databases.

=item * Do NOT end your SQL statements for testing within this framework with 
a semicolon.

=item * It is entirely feasible (and oh so cool), to have a "query server". Ie,
a cheap Linux box running MySQL which has no table but sql_catalog on it. And
all it does is serve the queries. Then your actual "data database" can be on 
a completely different machine. The idea is that SQL::Catalog connects to
the table sql_catalog based on its C<DSN> value (see README) while your
data database connects based on a different DSN.

=back

=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

Substantial contribution (and ass-kicking) by Jonathan Leffler.

=head1 SEE ALSO

=over 4

=item * L<Class::Phrasebook::SQL>. Performs a similar function. It
stores a "phrasebook" of SQL in XML files. Querying can be done with any
standard XML processor.

=item * L<DBIx::SearchProfiles>. Does query labeling and also has some
convenience functions for query retrieval. It does not store the SQL
in a database or make it searchable by table, column, or number of
placeholders. Your standard Perl data munging techniques would be the way to
do statistical analysis of your queries.

=item * http://perlmonks.org/index.pl?node_id=96268&lastnode_id=96273

A different approach is suggested using Perl modules. Interesting idea.

=item * "Leashing DBI"

http://perlmonks.org/index.pl?node=Leashing%20DBI&lastnode_id=96268

=back


=cut
