#     PREREQ_PM => { Data::Dumper=>q[2.00] }

all : force_do_it
	/usr/local/bin/perl5.8.2-threads Build
realclean : force_do_it
	/usr/local/bin/perl5.8.2-threads Build realclean
	/usr/local/bin/perl5.8.2-threads -e unlink -e shift Makefile

force_do_it :

build : force_do_it
	/usr/local/bin/perl5.8.2-threads Build build
clean : force_do_it
	/usr/local/bin/perl5.8.2-threads Build clean
code : force_do_it
	/usr/local/bin/perl5.8.2-threads Build code
diff : force_do_it
	/usr/local/bin/perl5.8.2-threads Build diff
dist : force_do_it
	/usr/local/bin/perl5.8.2-threads Build dist
distcheck : force_do_it
	/usr/local/bin/perl5.8.2-threads Build distcheck
distclean : force_do_it
	/usr/local/bin/perl5.8.2-threads Build distclean
distdir : force_do_it
	/usr/local/bin/perl5.8.2-threads Build distdir
distmeta : force_do_it
	/usr/local/bin/perl5.8.2-threads Build distmeta
distsign : force_do_it
	/usr/local/bin/perl5.8.2-threads Build distsign
disttest : force_do_it
	/usr/local/bin/perl5.8.2-threads Build disttest
docs : force_do_it
	/usr/local/bin/perl5.8.2-threads Build docs
fakeinstall : force_do_it
	/usr/local/bin/perl5.8.2-threads Build fakeinstall
help : force_do_it
	/usr/local/bin/perl5.8.2-threads Build help
install : force_do_it
	/usr/local/bin/perl5.8.2-threads Build install
manifest : force_do_it
	/usr/local/bin/perl5.8.2-threads Build manifest
ppd : force_do_it
	/usr/local/bin/perl5.8.2-threads Build ppd
skipcheck : force_do_it
	/usr/local/bin/perl5.8.2-threads Build skipcheck
test : force_do_it
	/usr/local/bin/perl5.8.2-threads Build test
testdb : force_do_it
	/usr/local/bin/perl5.8.2-threads Build testdb
versioninstall : force_do_it
	/usr/local/bin/perl5.8.2-threads Build versioninstall
