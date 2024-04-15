package Batch::Exec::Temp;

=head1 NAME

Batch::Exec::Temp - temporary file handling for the Batch Executive Framework.

=head1 AUTHOR

Copyright (C) 2024  B<Tom McMeekin> tmcmeeki@cpan.org

=head1 SYNOPSIS

  use Batch::Exec::Temp;

  my $ot1 = Batch::Exec::Temp->new('retain' => 1);

  my $ot2 = Batch::Exec::Temp->new('age' => 21600);	# six hours

  my $path1 = $ot1->file;
  my $path2 = $ot1->file;

  my $dir1 = $ot1->folder;
  my $dir2 = $ot2->folder;

  printf "found %d temporary objects\n", $ot1->count;


=head1 DESCRIPTION

Temporary object handling.  Utilises File::Temp to generate and create
temporary files and folders.  These are registered for the duration of the 
program and cleaned at the end (unless the retain flag is set).

In addition, older files which have been retained but are beyond the specified
retention age are searched for and removed.

=head2 ATTRIBUTES

=over 4

=item OBJ->age

Get ot set the purge age in epoch seconds.  A default applies.

=item OBJ->ext

Get ot set the extension for temporary filenames.  A default applies.

=item OBJ->retain

Get ot set automatic purge boolean.  A default applies: false.

=item OBJ->template

The temporary template (characters to use for uniqueness).  A default applies.

=back

=cut

use strict;

use parent 'Batch::Exec';

# --- includes ---
use Carp qw(cluck confess);
use Data::Dumper;
use File::Find;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;


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
	_tmpfile => undef,      # an array of temp files
	_tmpdir => undef,
	age => PURGE_AGE,
	ext => EXT_TMP,
	retain => 0,            # controls automatic aged purge 
	template => "XXXXXXXX",
);

#sub INIT { };

=head2 CLASS METHODS

=over 4

=cut

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

	#printf "DEBUG destroy object id [%s]\n", $self->Id;

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
	$self->reset;

	$self->{'_tmpfile'} = [];

	return $self;
}

=item OBJ->All

Return an array of registered temporary objects.  Not all object may exist
as such objects could be removed outside of the context of this class.

=cut

sub All {
	my $self = shift;

	$self->log->trace(sprintf "Id [%s] _tmpfile [%s]",
		$self->Id, Dumper($self->{'_tmpfile'}));

	return @{ $self->{'_tmpfile'} };
}

=item OBJ->Extant

Return an array of existing temporary objects.

=cut

sub Extant {
	my $self = shift;

	my @extant; for my $pn ($self->All) {

		push @extant, $pn
			if (-e $pn);
	}

	return @extant;
}

=back

=head2 OBJECT METHODS

=over 4

=item OBJ->clean

Delete all temporary objects registered within the context of this object.

=cut

sub clean {
	my $self = shift;
	my $count = 0;

	$self->log->trace(sprintf "tmpdir [%s] Id [%s]", $self->tmpdir, $self->Id)
		if ($self->Alive);

	for my $pn ($self->Extant) {

		$count++ unless ($self->delete($pn));

	}
	$self->log->info("$count temporary entries cleaned out")
		if ($self->Alive && $self->echo);

	return $count;
}

=item OBJ->count

Return a count of extant temporary objects.

=cut

sub count {
	my $self = shift;

	my $count = scalar($self->All);
	my $found = scalar($self->Extant);

	my $msg = sprintf "Id [%s] objects registered [%d] found [%s]",
		$self->Id, $count, $found;

	$self->log->info($msg)
		if ($self->Alive && $self->echo);

	return $found;
}

=item OBJ->default([EXPR])

Sets the current folder in which temporary files will be created.
If no argument is passed, or if the argument passed is not viable,
this will reset the folder to a failsafe default.
Returns the folder name.

=cut

sub default { 
	my $self = shift;
	my $dn = shift;

	my $f_dfl = 1; if (defined $dn) {	# directory specified

		my $msg1 = "temporary directory defaulted to [$dn]";
		my $msg2 = "possible invalid directory specified [$dn]";

		if ($self->is_rwx($dn)) {

			$self->{'_tmpdir'} = $dn;

			$f_dfl = 0;

			$self->log->info($msg1) if ($self->echo);

		} else {
			$self->log->warn($msg2);
		}
	}
	$self->reset
		if ($f_dfl); # null or invalid directory, reset default

	return $self->{'_tmpdir'};
}

=item OBJ->file

Convenience function to register a unique temporary file name.
An empty file will will be created and the pathname to it returned.

=cut

sub file {
	my $self = shift;

	my $pn = $self->register('f');
	my $msg = sprintf "Id [%s] created temporary file [$pn]", $self->Id;

	$self->log->info($msg)
		if ($self->echo);

	return $pn;
}

=item OBJ->folder

Convenience function to register a unique temporary folder name.
A folder will will be created and the pathname to it returned.

=cut

sub folder {
	my $self = shift;

	my $dn = $self->register('d');
	my $msg = sprintf "Id [%s] created temporary folder [$dn]", $self->Id;

	$self->log->info($msg)
		if ($self->echo);

	return $dn;
}

=item OBJ->register(EXPR)

Generates, creates and registers the pathname for a temporary
file or directory based on the EXPR passed, which must be 'f' or 'd'.

Returns a pathname.

=cut

sub register {
	my $self = shift;
	my $type = shift;
	confess "SYNTAX: register(EXPR)" unless (defined $type);
	my $pn;

	#my $tpl = join('.', $self->prefix . $self->ext, $self->template);
	my $tpl = join('_', $self->prefix, $self->template);

	$self->log->trace("type [$type] tpl [$tpl]");
	$self->log->trace(sprintf "prefix [%s] dir [%s]", $self->prefix, $self->tmpdir);

	if ($type eq 'f') {
		my $fh;

		($fh,$pn) = tempfile($tpl, DIR => $self->tmpdir, SUFFIX => $self->ext);
		$self->header($fh);

		close($fh);	# don't need this open

	} elsif ($type eq 'd') {

		$pn = tempdir($tpl, DIR => $self->tmpdir);

	} else {
		$self->log->logconfess("FATAL invalid type [$type]");
	}

	$self->log->trace("type [$type] pn [$pn]");

	push @{ $self->{'_tmpfile'} }, $pn;

	return $pn;
}

=item OBJ->purge

Search for old temporary files and remove if older than the purge age.

=cut

sub purge {	
	my $self = shift;

	my $now = time;
	my $count = 0;
	my $dn = $self->tmpdir;
	my $rep = $self->prefix;

	$rep =~ s/[\.\-]/\\$&/g;

	$self->log->trace("now [$now] dn [$dn] rep [$rep]")
		if ($self->Alive);

	my $prep = sub { # pre-process for name matches (strings not files!)

		$self->log->trace(sprintf "prep rep [$rep] argv [%s]", Dumper(\@_))
			if ($self->Alive);

		my @valid; for (@_) {

			push @valid, $_ if ($_ =~ /^$rep/);
		}
		$self->log->trace(sprintf "prep valid [%s]", Dumper(\@valid))
			if ($self->Alive);

		return @valid;
	};
	my $wanted = sub { 
		my $pn = $File::Find::name;

		return if ($pn eq $dn);	# don't really need to purge this!

		return unless (-f $pn || -d $pn);

		$self->log->trace("name match [$pn]")
			if ($self->Alive);

		my ($atime,$mtime, $ctime) = (stat($pn))[8..10];

		my $age = ($now - $mtime);

		if ($self->Alive) {

			$self->log->trace("now [$now] atime [$atime] ctime [$ctime] mtime [$mtime]");

			$self->log->trace(sprintf "age [$age] threshold [%d]", $self->age);
		}

		if ($age > $self->age) {
			$count++ unless ($self->delete($pn));
#		} else {
#			$self->log->debug("SKIPPING purge [$pn]")
#				if ($self->Alive);
		}
	};
	return 0 unless ($self->is_rwx($dn));

	$self->log->info(sprintf "finding aged temporary files under [$dn]")
		if ($self->Alive);

	finddepth({preprocess => $prep, wanted => $wanted, no_chdir => 1}, $dn);

	$self->log->info("$count temporary entries purged")
		if ($self->Alive);

	return $count;
}

=item OBJ->reset

Reset the default folder in which temporary files will be created.
This is a failsafe routine, provinding a viable location for files.

=cut

sub reset { 
	my $self = shift;

	my $dn = DN_TMP_DFL;

	$self->log->info("resetting temporary location to [$dn]")
		if ($self->echo);

	$self->{'_tmpdir'} = $dn;

	return $self->tmpdir;
}

=item OBJ->tmpdir

Read-only method to return the current temporary folder.

=cut

sub tmpdir {
	my $self = shift;

	return $self->{'_tmpdir'};
}

=back

=head2 ALIASED METHODS

The following method aliases have also been defined:

	alias		base method
	------------	------------	
	mktmpdir	folder
	mktmpfile	file

=cut

*mktmpdir = \&folder;
*mktmpfile = \&file;

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

L<perl>, L<File::Find>, L<File::Spec>, L<File::Temp>.

=cut

