#!/usr/bin/perl
#
# 02_bulk.t - test harness for the Batch::Exec::Temp module: general
#
use strict;

use Data::Compare;
use Data::Dumper;
use Logfer qw/ :all /;
use Test::More tests => 51;

BEGIN { use_ok('Batch::Exec::Temp') };


# -------- constants --------

# -------- global variables --------
my $log = get_logger(__FILE__);
my $cycle = 1;
my $age = 1;
my $wait = $age * 3;
my $max = 3;


# -------- sub-routines --------

# -------- main --------
my $ot1 = Batch::Exec::Temp->new('echo' => 1, 'retain' => 1);
my $ot2 = Batch::Exec::Temp->new('echo' => 1, 'age' => $age);

isa_ok($ot1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;
isa_ok($ot2, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;


# ---- clean -----
my $expected = $max * 2;	# will create max files and max folders
my @temps;

for (my $ss = 0; $ss < $max; $ss++) {

	push @temps, $ot1->file;
	push @temps, $ot2->file;

	push @temps, $ot1->folder;
	push @temps, $ot2->folder;
}

for (my $ss = 0; $ss < @temps; $ss++) {

	ok(-e $temps[$ss],	"exists clean $cycle");

	$cycle++;
}

is($ot1->clean, $expected,	"clean count $cycle"); $cycle++;
is($ot2->clean, $expected,	"clean count $cycle"); $cycle++;

for (my $ss = 0; $ss < @temps; $ss++) {

	ok(! -e $temps[$ss],	"gone clean $cycle");

	$cycle++;
}


# ---- purge -----
$expected = $max * 4;	# first object will retain so second object has double
my @temp1 = ();
my @temp2 = ();

isnt($ot1->age, $age,	"purge age $cycle"); $cycle++;
is($ot2->age, $age,	"purge age $cycle"); $cycle++;

for (my $ss = 0; $ss < $max; $ss++) {

	push @temp1, $ot1->file;
	push @temp2, $ot2->file;

	push @temp1, $ot1->folder;
	push @temp2, $ot2->folder;
}

$log->info("sleeping for $wait seconds"); sleep($wait);

for (my $ss = 0; $ss < @temp1; $ss++) {

	ok(-e $temp1[$ss],	"exists purge $cycle");

	$cycle++;
}

$log->info("expecting retain");
is($ot1->purge, 0,	"purge count $cycle"); $cycle++;

$ot1 = ();	# force a purge, but no deletions because of retain...

#... so all temp files should still exist

for (my $ss = 0; $ss < @temp1; $ss++) {

	ok(-e $temp1[$ss],	"exists purge $cycle");

	$cycle++;
}

for (my $ss = 0; $ss < @temp2; $ss++) {

	ok(-e $temp2[$ss],	"exists purge $cycle");

	$cycle++;
}

# now expecting double the number of files to be purged.

$log->info("expecting purge");
is($ot2->purge, $expected,	"purge count $cycle"); $cycle++;


__END__

=head1 DESCRIPTION

02_bulk.t - test harness for the Batch::Exec::Temp class

=head1 VERSION

$Revision: 1.4 $

=head1 AUTHOR

B<Tom McMeekin> tmcmeeki@cpan.org

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<perl>, L<Batch::Exec::Temp>.

=cut

