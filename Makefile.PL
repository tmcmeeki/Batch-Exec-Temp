use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $_swap_vers = 'find $(DISTVNAME) -type f -exec egrep -q _IDE_REVISION_ {} \; -exec sed -i "s/_IDE_REVISION_/$(VERSION)/" {} \; -print ;' .
'perldoc -uT $(DISTVNAME)/$(VERSION_FROM) > README.pod';

WriteMakefile(
    NAME              => 'Batch::Exec::Temp',
    VERSION_FROM      => 'lib/Batch/Exec/Temp.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
	'Batch::Exec' => '1.013',
        'Carp' => '0',
        'Data::Dumper' => '0',
        'Log::Log4perl' => '0',
}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Batch/Exec/Temp.pm', # retrieve abstract from module

    dist              => { PREOP => $_swap_vers, },
    AUTHOR            => 'TMCMEEKI  <tmcmeeki@cpan.org>',
    LICENSE           => 'gpl_3',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
