perl Makefile.PL PREFIX=$PREFIX
make
make test
make install
pod2text README.pod > README
pod2text Catalog.pm > Catalog.text
make tardist
cd db-creation; perl postgresql.renderer > postgresql.sql
