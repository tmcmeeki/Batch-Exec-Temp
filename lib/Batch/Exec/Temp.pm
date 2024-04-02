package Batch::Exec::Temp;

=head1 NAME

Batch::Exec::Temp - temporary file handling for the Batch Executive Framework.

=head1 AUTHOR

Copyright (C) 2024  B<Tom McMeekin> tmcmeeki@cpan.org

=head1 SYNOPSIS

  use Batch::Exec::Temp;


=head1 DESCRIPTION

Temporary file and folder handling.

=head2 ATTRIBUTES

=over 4

=item OBJ->age

Get ot set the purge age in epoch seconds.  A default applies.

=item OBJ->ext

Get ot set the extension for temporary filenames.  A default applies.

=item OBJ->retain

Get ot set automatic purge boolean.  A default applies: false.

=item OBJ->tmpdir

Get ot set the folder in which temporary files are created.  A default applies.

=back

=cut

use strict;

use parent 'Batch::Exec';

# --- includes ---
use Carp qw(cluck confess);
use Data::Dumper;


# --- package constants ---
use constant DN_TMP_DFL => File::Spec->tmpdir;

use constant EXT_TMP => ".tmp";

use constant PURGE_AGE => 86400;        # epoch seconds, 3600 sec/hr = 24 hr


# --- package globals ---
our $AUTOLOAD;
#our @EXPORT = qw();
#our @ISA = qw(Exporter);
our @ISA;
our $VERSION = sprintf "%d.%03d", q[_IDE_REVISION_] =~ /(\d+)/g;


# --- package locals ---
my $_n_objects = 0;

my %_attribute = (	# _attributes are restricted; no direct get/set
	_tmpfile => undef,      # a hash of temp files
	age => PURGE_AGE,
	ext => EXT_TMP,
	retain => 0,            # controls automatic aged purge 
	template => "XXXXXXXX",
	tmpdir => DN_TMP_DFL,
);

#sub INIT { };

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or confess "$self is not an object";

	my $attr = $AUTOLOAD;
	$attr =~ s/.*://;   # strip fully−qualified portion

	confess "FATAL older attribute model"
		if (exists $self->{'_permitted'} || !exists $self->{'_have'});

	confess "FATAL no attribute [$attr] in class [$type]"
		unless (exists $self->{'_have'}->{$attr} && $self->{'_have'}->{$attr});
	if (@_) {
		return $self->{$attr} = shift;
	} else {
		return $self->{$attr};
	}
}


sub DESTROY {
	local($., $@, $!, $^E, $?);
	my $self = shift;

	#printf "DEBUG destroy object id [%s]\n", $self->{'_id'});

	-- ${ $self->{_n_objects} };
}


sub new {
	my ($class) = shift;
	my %args = @_;	# parameters passed via a hash structure

	my $self = $class->SUPER::new;	# for sub-class
	my %attr = ('_have' => { map{$_ => ($_ =~ /^_/) ? 0 : 1 } keys(%_attribute) }, %_attribute);

	bless ($self, $class);

	map { push @{$self->{'_inherent'}}, $_ if ($attr{"_have"}->{$_}) } keys %{ $attr{"_have"} };

	while (my ($attr, $dfl) = each %attr) { 

		unless (exists $self->{$attr} || $attr eq '_have') {
			$self->{$attr} = $dfl;
			$self->{'_have'}->{$attr} = $attr{'_have'}->{$attr};
		}
	}

	while (my ($method, $value) = each %args) {

		confess "SYNTAX new(, ...) value not specified"
			unless (defined $value);

		$self->log->debug("method [self->$method($value)]");

		$self->$method($value);
	}
	# ___ additional class initialisation here ___
#	$self->log->debug(sprintf "self [%s]", Dumper($self));

	return $self;
}

=head2 METHODS

=over 4

=item OBJ->clean

Delete all temp files.

=cut

sub clean {
	my $self = shift;
	my $count = 0;

	$self->log->trace(sprintf "tmpdir [%s] _id [%s] _tmpfile [%s]", $self->tmpdir, $self->_id, Dumper($self->_tmpfile))
		if ($self->Alive());

	return $count
		unless (defined $self->_tmpfile);

	while (my $pn = pop @{ $self->_tmpfile }) {

		next unless (-e $pn); # may have already been deleted elsewhere so check if it actually exists

		if ($self->delete($pn)) {

			push @{ $self->_tmpfile }, $pn;

		} else {

			$count++;
		}
	}
	$self->log->info("$count temporary entries cleaned out")
		if ($self->Alive() && $self->{'echo'});

	return $count;
}

=item OBJ->hometmp

Add description here

=cut

sub hometmp {	# read-only method!
	my $self = shift;
	my $dn_home = $self->homedir;
	my $dn_tmp = File::Spec->catdir($dn_home, "tmp");

	return $dn_tmp;		# nice alternative location for temp files
}

=item OBJ->default

Add description here

=cut

sub default { 
	my $self = shift;
	my $dn = shift;

	my $f_default = 1;
	my $verb = "defaulted";

	if (defined $dn) {	# someone has specified a directory to use

		unless ($self->ckdir_rwx($dn)) {

			$self->tmpdir($dn);

			$verb = "set";

			$f_default = 0;

		} else {
			$self->log->warn("possible invalid directory specified [$dn]")
		}
	}

	if ($f_default) {	# null or invalid directory, reset defaults

		$dn = DN_TMP_DFL;

		$self->tmpdir($dn);
	} 
	$self->log->info("temporary directory $verb to [$dn]")
		if ($self->{'echo'});
	
	return $self->tmpdir;
}

=item OBJ->mktmpdir

Add description here

=cut

sub mktmpdir {
	my $self = shift;

	my $dn = $self->_register_tmpfile('d');

	$self->log->info("created temporary directory [$dn]");

	return $dn;
}

=item OBJ->mktmpfile

Add description here

=cut

sub mktmpfile {
	my $self = shift;

	my $pn = $self->_register_tmpfile('f');

	$self->log->info("created temporary file [$pn]")
		if ($self->{'echo'});

	return $pn;
}

=item OBJ->purge

Add description here

=cut

sub purge {	# search for old temp files and remove
	my $self = shift;

	my $now = time;
	my $count = 0;
	my $dn = $self->tmpdir;
	my $rep = $self->prefix;

	$rep =~ s/[\.\-]/\\$&/g;

	my $prep = sub { # pre-process for name matches (strings not files!)

#		$self->log->debug(sprintf "prep rep [$rep] argv [%s]", Dumper(\@_));
		my @valid; for (@_) {

			push @valid, $_ if ($_ =~ /^$rep/);
		}
		$self->log->trace(sprintf "prep valid [%s]", Dumper(\@valid));

		return @valid;
	};
	my $wanted = sub { 
		my $pn = $File::Find::name;

		return if ($pn eq $dn);	# don't really need to purge this!

		return unless (-f $pn || -d $pn);

		$self->log->trace("matched [$pn]");

		my ($atime,$mtime, $ctime) = (stat($pn))[8..10];

		my $age = ($now - $mtime);

		if ($self->Alive) {

			$self->log->trace("now [$now] atime [$atime] ctime [$ctime] mtime [$mtime]");

			$self->log->trace(sprintf "age [$age] threshold [%d]", $self->age);
		}

		if ($age > $self->age) {
			$count++ unless ($self->delete($pn));
		}
	};
	return 0 if($self->ckdir_rwx($dn));

	$self->log->info(sprintf "finding aged temporary files under [$dn]")
		if ($self->Alive()); # && $self->{'echo'});

	finddepth({ preprocess => $prep, wanted => $wanted, no_chdir => 1 }, $dn);

	$self->log->info("$count temporary entries purged")
		if ($self->Alive()); # && $self->{'echo'});

	return $count;
}

=item OBJ->_register_tmpfile

Add description here

=cut

sub _register_tmpfile {
	my $self = shift;
	my $type = shift;
	confess "SYNTAX: _register_tmpfile(EXPR)" unless defined ($type);

	my $pn = $self->_mktmp($type);

	if (defined $self->{'_tmpfile'}) {

		push @{ $self->{'_tmpfile'} }, $pn;

	} else {
		$self->{'_tmpfile'} = [ $pn ];
	}

	$self->log->trace(sprintf "registered new temp entry [$pn] in [%s]", Dumper($self->{'_tmpfile'}));

	return $pn;
}

=back

=head2 ALIASED METHODS

The following method aliases have also been defined:

	alias		base method
	------------	------------	
	isnt_foo	is_notfoo
	isnt_bar	is_notbar

=cut

#*isnt_foo = \&is_notfoo;
#*isnt_bar = \&is_notbar;

#sub END { }

1;

__END__


=head1 VERSION

_IDE_REVISION_

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3 of the License,
or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<perl>.

=cut

