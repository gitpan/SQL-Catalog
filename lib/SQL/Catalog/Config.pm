
#
# SQL::Catalog configuration
#
# Autogenerated by Makefile.PL, do not edit!
#

    package SQL::Catalog::Config;

    $default = 'Pg' ;

    @confs   = ('Pg') ; 
    %param   =
	(
         'Pg' => 
        {
         'UserName' => 'postgres',
         'DataSource' => 'dbi:Pg:dbname=mydb',
         'Password' => '',
         'name' => 'Postgres',
        },

	) ;

    $defaultparam = $param{'Pg'} ;

    1 ;
