use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SQL::Catalog',
    'VERSION_FROM'	=> 'Catalog.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      SQL::Statement => 0.1,
	DBI => 1.19
    }, # e.g., Module::Name => 1.1
);
