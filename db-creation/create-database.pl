#!/usr/bin/perl

use warnings;
use strict;
use DBIx::Renderer ':all';

use constant TYPE_NAME     => VARCHAR(40);
use constant TYPE_PASSWORD => ( VARCHAR(20), NOTNULL );
use constant TYPE_MANDNAME => ( VARCHAR(255), NOTNULL );  # mandatory name
use constant TYPE_PRICE    => ( FLOAT4, NOTNULL, DEFAULT(0) );

my $struct = 
    [
     sql_catalog => 
     [
      label    => { VARCHAR(60) },
      cmd      => { VARCHAR(20) },
      columns  => { VARCHAR(255) },
      tables   => { VARCHAR(255) },
      phold    => { INT4 },
      query    => { VARCHAR(32768) },
      ],
     ];

# use Data::Dumper; print Dumper($struct); exit;

my $renderer = DBIx::Renderer::get_renderer('Postgres');
print $renderer->create_schema($struct);

__END__

=head1 NAME

mydb.pl - DBIx::Renderer demonstration program

=head1 SYNOPSIS

./mydb.pl | psql

=head1 DESCRIPTION

This is a demonstration program for C<DBIx::Renderer>, using the Postgres
renderer to construct a sample shop database. Its output should be bona
fide SQL that can be passed to Postgres.

=head1 NOTES

For extra brownie points, install C<GraphViz::DBI> (also by yours truly
and available from CPAN) and use C<dbigraph.pl> to graph the tables and
their connections. You should arrive at the same graph as was bundled
in the C<exmaples/> directory of C<GraphViz::DBI>, since this is the
database used to create it.

=head1 BUGS

None known.

=head1 AUTHOR

Marcel GrE<uuml>nauer E<lt>marcel@codewerk.comE<gt>

=head1 COPYRIGHT

Copyright 2001 Marcel GrE<uuml>nauer. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

DBI(3pm).

=cut

