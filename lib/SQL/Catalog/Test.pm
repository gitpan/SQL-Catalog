package SQL::Catalog::Test;

use DBIx::AnyDBD;

###########################
# Database Handle Methods #
###########################

# class attributes
foreach my $att ( qw( dsn user password connect_attributes ) )
{
    eval "
{
    my \$$att;
    sub set_$att {
        shift; # class name
        \$$att = shift;
    }
    sub $att {
        return \$$att;
    }
}
";
}

sub instance {
    if ($DB && $DB->ping) {
        # rollback uncommited transactions
        # this doesn't work where multiple nested method calls might call instance()
        # $DB->rollback;
        
        return $DB;
    }

    my $class = shift;
    
    my $x = 0;
    do {
	if ($DB) {
            eval { $DB->disconnect; };
            undef $DB;
	}
        $class->connect;
        return $DB if $DB && $DB->ping
    } until ($x++ > MAX_ATTEMPTS);

    die "Couldn't connect to database";
}

sub connect {
    my $class = shift;

    $DB = DBIx::AnyDBD->new( dsn => $class->dsn,
			   user => $class->user,
			   pass => $class->password,
			   attr => $class->connect_attributes,
			   package => $class,
			 );
}


1;
