package SQL::Catalog;

use DBI;
use SQL::Statement;
use Data::Dumper;
use Carp;

require 5.005_62;
use strict;
use warnings;

our $VERSION = sprintf '%s', q{$Revision: 1.10 $} =~ /\S+\s+(\S+)/ ;

# author , optional
# denormalize on label

# Preloaded methods go here.
sub load_sql_from {
    my $file = shift;
    -e $file or croak "File $file does not exist";
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
       warn
	   "Cannot parse statement (statement cannot end with semicolon): $@";
       warn 
	   "Continuing without SQL validation (good luck).";
       my $u='unparseable';
       return { 
	   command => $u,
	   params =>  -1,
	   columns => [
		       {
			   table  => $u,
			   column => $u
			   }
		       ],
	    } ;
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

sub allowable {
    my ($key,$val) = @_;
    my %allowable = 
	( label => sub { $_[0] !~ /\s/ } );
    $allowable{$key}->($val);
}

sub register {

    my ($class,$file,$label,$comments) = @_;

    $file and $label and $comments or
	die<<EOD;
file, label, and comments are all required fields to register a query
EOD

    allowable label => $label or die 'label cannot contain whitespace';


    my $sql = load_sql_from $file;

   die "you must create a label for this SQL: $sql" unless $label;
 
    my $parse = parse_sql $sql;

   #   die Dumper(\@columns, \@tables, $params, \$command);
 
    
   my $dbh = db_handle;

    my $insert='insert into sql_catalog
       (label, cmd, phold, author, query, comments)
values (    ?,   ?,     ?,      ?,     ?,        ?)';

   my $insert_ft='insert into sql_catalog_ft
       (label_ft,  tbl, col)
values (       ?,   ? ,   ?)';


   my $sth_primary = $dbh->prepare($insert);
   my $sth_ft      = $dbh->prepare($insert_ft);

    my $uname = getpwuid($<);

    warn sprintf "BIND %s . %s . %s . %s . %s . %s   ",
    ($label, $parse->{command}, $parse->{params}, 
	$uname, $sql, $comments);

   $sth_primary->execute 
       ($label, $parse->{command}, $parse->{params}, 
	$uname, $sql, $comments);
   
  
   for my $column (@{$parse->{columns}}) {	
       $sth_ft->execute($label, $column->{table}, $column->{column});
   }	

    open R, ">$sql.sql_cat" or die "can't open register:!";

    my $log = "[$label] inserted as\n[$sql]\n";

    print R $log;
    print $log;

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
    my ($class,$file,@bind_args) = @_;
    warn "NO PLACEHOLDER VALUES SUPPLIED" unless @bind_args;
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

SQL::Catalog - label queries, db independant SQL, separate Perl and SQL

=head1 SYNOPSIS

 shell% cd sql_lair/city,date/weather/1/

 shell% cat concrete.sql 
 select city, date from weather where temp_lo < 20 and temp_hi > 40 LIMIT 10
 shell% sql_test concrete.sql 
 shell% cat testexec.out # see results of prepare, execute on this

 shell% cat abstract.sql
 select city, date from weather where temp_lo < ? and temp_hi > ?
 shell% sql_test abstract.sql 55 # send in placeholder value
 shell% cat testexec.out # to see results... looks good

 shell% sql_register abstract.sql basic_weather "basic weather query"
 [basic_weather] inserted as 
 [select city from weather where temp_lo < ? and temp_hi > ?]

 ... then in a Perl program (e.g. test.pl in this distribution)
 my $dbh = SQL::Catalog->db_handle; # optional - get the handle as you please
 my $sql = SQL::Catalog->lookup('hi_and_low');
 my $sth = $dbh->prepare($sql);
 $sth->execute(55);

 my $rows = $sth->rows;


=head1 DESCRIPTION

Over time, it has become obvious that a few things about SQL queries are 
necessary. And before this module, time-consuming:

=over 4

=item * database independence

You may at some time to be forced to deploy an application which has to
work on more than one database. Prior to SQL::Catalog, there were two
choices - DBIx::AnyDBD and DBIx::Recordset. SQL::Catalog will work well
alongside the latter.

Note though that because some databases can do in one query what takes
4 in another (ie, Oracle has C<SELECT * FROM CREATE TABLE ...>),
you may have to create subclasses of your database layer classes to actually
handle each needed function. This is what DBIx::AnyDBD handles for you.

=item * labelled queries

A large, well-scaled business database application has several layers
with simple well-defined tasks. The layer just above the database does
database things. It inserts. It retrieves. It updates. etc, etc. Call
this the database application layer. Just above the database
application layer is the business object layer. These are conceptual
entities whose data structures are program data structures. For
permanent stores, they make simple, technology-agnostic requests of
the database application layer, which then takes the business data and 
stores it as database data. Then above this we have the application layer. And
this layer makes use of business objects, ldap objects, web objects,
what have you, to string together a complete application.

=item * queryable queries

That's right, you want to be able to query on the queries
themselves. It makes it easy to do a study on
just what queries are doing what.

=item * separation of concerns

By now, everyone has heard that phrase: "my templating module is the
best because it allows the HTML designer to work separately from the
Perl programmer." Well, given that databases are another foreign
technology to Perl proper, it only makes sense that the same ability
that is afforded to HTML designers be afforded to SQL programmers.

=item * centralization of queries

This makes it easy for someone to see how 
you did something so they can imitate.

=item * memory preservation

You may be sitting there thinking "this is no better than a Perl
hashref". And if you are, then I congratulate you on making it to the
6th bulleted item instead of impatiently finding something else to do.
Anyway, the problem with using a Perl hashref is that it will consume 
memory and in a large system memory is precious.

Furthermore, you don't get the querying capabilities with a Perl hashref.

=back

SQL::Catalog addresses all of these issues.

=head1 COMMON STEPS TO USAGE

=head2 Develop your concrete query in a db shell

The first step to developing a database query is to play around at the 
db shell. In this case, you normally don't have any placeheld values. You just
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

It stores each query in a database table with the label as key and
the SQL query as the one value for that key. Then there is a foreign
table with a number of useful query attributes such as type of query, 
tables and columns used and number of placeholders.

Right now we have schema creation and SQL code which works for 
MySQL (thanks to Jason W. May), Informix (thanks to Jonathan Leffler) 
and Postgresql (thanks to me, although I did use Marcel Grunaer's
DBIx::Renderer to make it) and welcome more.

The queries are stored in these tables
(this file is C<db-creation/postgresql.sql>):

 CREATE TABLE sql_catalog (
        label varchar(80) ,
        cmd varchar(40) ,
        phold int4 ,
        author varchar(40) ,
        query varchar(65536) ,
        comments varchar(1600) ,
        PRIMARY KEY (label)
			  );
CREATE TABLE sql_catalog_ft (
        label_ft varchar(80) ,
        tbl varchar(255) ,
        col varchar(255) ,
        PRIMARY KEY (label_ft)
			     );


And here is the result of ONE sql_register:

 mydb=# select * from sql_catalog_ft;
 label_ft |   tbl   |   col   
 ----------+---------+---------
 basic_weather     | weather | city
 basic_weather     | weather | date
 basic_weather     | weather | temp_lo
 basic_weather     | weather | temp_hi
 (4 rows)

 mydb=# select * from sql_catalog;
 label |  cmd   | phold |  author  |                                    query                                     | comments 
 -------+--------+-------+----------+------------------------------------------------------------------------------+----------
 basic_weather  | SELECT |     1 | metaperl | select city, date, temp_lo, temp_hi from weather where temp_lo < ? LIMIT 40
 | ahah
 (1 row)


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

=item * When dropping these tables, you will also have to drop one index

=back

=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

Substantial contribution (and ass-kicking) by Jonathan Leffler.
MySQL table creation code contribution by Jason W. May.


=head1 SEE ALSO

There are several related modules on CPAN. Each do some of what
SQL::Catalog does.

=over 4

=item * L<Ima::DBI|Ima::DBI> provides an object-oriented interface to
connection and sql management.

=item * L<DBIx::Librarian|DBIx::Librarian> provides labelled access to 
queries and shortens the prepare-execute ritual a bit.

=item * L<Class::Phrasebook::SQL|Class::Phrasebook::SQL>
 stores a "phrasebook" of SQL in XML
files. Allows for retrieval of queries via a convenient API. The
querying of queries that SQL::Catalog supports can be done using an
XML processor along with SQL::Statement.

=item * L<DBIx::SearchProfiles|DBIx::SearchProfiles>. 
Does query labeling and also has some
convenience functions for query retrieval. It does not store the SQL
in a database or make it searchable by table, column, or number of
placeholders. Your standard Perl data munging techniques would be the way to
do statistical analysis of your queries.

=item * Queries stored in Perl modules

A different approach is suggested using Perl modules. Interesting idea.

http://perlmonks.org/index.pl?node_id=96268&lastnode_id=96273

=item * "Leashing DBI"

Various issues in building applications on top of DBI.

http://perlmonks.org/index.pl?node=Leashing%20DBI&lastnode_id=96268

=back


=cut
