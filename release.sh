perl Makefile.PL PREFIX=$PREFIX
make
make install
pod2text README.pod > README
pod2text Catalog.pm > Catalog.text
make tardist