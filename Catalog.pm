package SQL::Catalog;


use DBI;
use SQL::Statement;
use Data::Dumper;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SQL::Catalog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.
sub load_sql_from {
    my $file = shift;
    open A, $file or die "cannot open $file";
    join '', <A>;
}

sub db_handle {
    my $connect = 'dbi:Pg:dbname=mydb';

    DBI->connect($connect,'postgres','money1',
			   { RaiseError => 1,
			     PrintError => 1
			     }
			   );
    
}

sub register {

    my ($class,$file,$label) = @_;

    my $sql = load_sql_from $file;

   die "you must create a label for this SQL: $sql" unless $label;
   # Create a parser
   my($parser) = SQL::Parser->new('Ansi');

   # Parse an SQL statement
   $@ = '';
   my ($stmt) = eval {
     SQL::Statement->new($sql, $parser);
   };
   if ($@) {
       die "Cannot parse statement: $@";
   }

   # Query the list of result columns;
   my @columns = $stmt->columns;    # Array context
   my $columns = join ',', map { $_->{table} . '.' . $_->{column} } @columns;

   # Likewise, query the tables being used in the statement:
   my @tables = $stmt->tables;      # Array context
   my $tables = join ',', map { $_->{table} } @tables;

   my $params = $stmt->params;

   my $command = $stmt->command;

#   die Dumper(\@columns, \@tables, $params, \$command);
 
   my $insert='insert into sql_catalog
       (label,  query,  tables, columns, cmd, phold)
values (  ?  ,   ?   ,    ?   ,    ?   ,  ? ,   ?  )';


    
   my $dbh = db_handle;

#   warn $insert;
#   warn "$label, $sql, $tables, $columns, $command, $params";

   my $sth = $dbh->prepare($insert);

   $sth->execute($label, $sql, $tables, $columns, $command, $params);

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


    my $dbh = db_handle;
    my $sth = $dbh->prepare($sql);


    
    $sth->execute(@bind_args);

    use Data::Dumper;

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

SQL::Catalog - test, label, and retrieve SQL queries

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

Over time, it has become obvious that two things about SQL queries are 
necessary. One, you want to be able to get a query by a label. Two, you want 
to be able to look through old queries to see if someone else has written
one similar to what you want. Three, you want the database guru to develop
queries on his own and be able to register them for your use without 
interfering with him. Four, you want to be able to answer questions such as
"what queries are doing a select on such-and-such tables".

Well, wait no longer, for your solution has arrived.

=head1 Common Steps to Usage

=head2 Develop your "concrete query in a db shell"

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

But let's test this query next:

 sql_test abstract.sql 34

And let's cat testexec.out to see the results.

=head2 Register your query

 sql_register abstract.sql city_date_via_temp_hi

and the system tells you

 [city_date_via_temp_hi] saved as
 [select city, date from weather where temp_hi > ?] 

=head2 Use your query from DBI:

 use SQL::Catalog;

 my $dbh = SQL::Catalog->db_handle;
 my $SQL = SQL::Catalog->lookup('city_date_via_temp_hi') or die "not found";
 my $sth = $dbh->prepare($SQL, $cgi->param('degrees'));
  .... etc

=head1 What you must do

=over 4

=item * edit sub db_handle so it gets a database handle. 

=item * copy the sql_* scripts to a place on your C<$PATH>

=item * create a table named sql_catalog. a script for Postgresql is provided.

=back

=head1 What SQL::Catalog does

It stores each query in a database table. I could have gone for
something more fancy in database design but wanted to maintain
database independence without requiring extra tools for schema
creation and database use. 

The queries are stored in this table:

 CREATE TABLE sql_catalog (
	query varchar(65535) , # the actual query
	tables varchar(255) ,  # tables used
	columns varchar(255) , # fields selected
	cmd varchar(40) ,      # SELECT, INSERT, UPDATE, etc
	phold int4   # number of bind_values
 );


Query field omitted for brevity. It has (wouldya guess) the SQL query.

  mydb=# select label,cmd,columns,tables,phold from sql_catalog;
      label     |  cmd   | columns                          | tables  | phold 
 ---------------+--------+---------------------------------------------------
 weather_hi    | SELECT | weather.city,weather.date        | weather |     1
 hi_and_low    | SELECT | weather.city                     | weather |     2


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=head1 SEE ALSO

=over 4

=item * L<Class::Phrasebook::SQL> performs a similar function. It
stores a "phrasebook" of SQL in XML files. It doesn't support
placeholders. It also has some rather daunting satellite module
requirements. 

=item * L<DBIx::SearchProfile> does query labeling and also has some
convenience functions for query retrieval. It does not store the SQL
in a database or make it searchable by table, column, or number of
placeholders. 

=back

=cut
