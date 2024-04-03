#!/usr/bin/perl
#
# 00_basic.t - test harness for the Batch::Exec::Temp class: basics
#
use strict;

use Data::Dumper;
use Logfer qw/ :all /;
#use Log::Log4perl qw/ :easy /;
use Test::More tests => 90;

BEGIN { use_ok('Batch::Exec::Temp') };


# -------- constants --------


# -------- global variables --------
my $log = get_logger(__FILE__);

my $cycle = 1;


# -------- subroutines --------


# -------- main --------
my $obt1 = Batch::Exec::Temp->new;
isa_ok($obt1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

my $obt2 = Batch::Exec::Temp->new(echo => 1, fatal => 0);
isa_ok($obt2, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;


# -------- simple attributes --------
my @attr = $obt1->Attributes;
my $attrs = 19;
is(scalar(@attr), $attrs,		"class attributes");
is(shift @attr, "Batch::Exec::Temp",	"class okay");

for my $attr (@attr) {

	my $dfl = $obt1->$attr;

	my ($set, $type); if (defined $dfl && $dfl =~ /^[\-\d\.]+$/) {
		$set = -1.1;
		$type = "f`";
	} else {
		$set = "_dummy_";
		$type = "s";
	}

	is($obt1->$attr($set), $set,	"$attr set cycle $cycle");
	isnt($obt1->$attr, $dfl,	"$attr check");

	$log->debug(sprintf "attr [$attr]=%s", $obt1->$attr);

	if ($type eq "s") {
		my $ck = (defined $dfl) ? $dfl : "_null_";

		ok($obt1->$attr ne $ck,	"$attr string");
	} else {
		ok($obt1->$attr < 0,	"$attr number");
	}
	is($obt1->$attr($dfl), $dfl,	"$attr reset");

        $cycle++;
}


# -------- Inherit --------
is($obt1->Inherit($obt2), $attrs - 1,	"inherit same attribute count");


# ---- miscellaneous defaults -----
ok($obt1->age > 0,		"age default");
like($obt1->ext, qr/tmp/,	"ext default");
is($obt1->retain, 0,		"retain default");


# ---- tmpdir -----
my $dn_reset = $obt2->tmpdir;
my $dn_valid = ".";
my $dn_inval = '_$$$_';

ok(-d $obt2->tmpdir,		"tmpdir default exists");
ok(-d $dn_valid,		"tmpdir override exists");

ok($obt2->tmpdir($dn_valid),	"tmpdir is read-only");


# ---- reset -----
is($obt1->reset, $dn_reset,		"reset to default");
is($obt1->reset, $obt2->reset,		"reset matches");


# ---- default -----
ok(-d $obt2->default,			"default resets default");
isnt($obt2->default, $dn_inval,		"check default");

ok(-d $obt2->default($dn_valid),	"override valid default");
ok(-d $obt2->default($dn_inval),	"override invalid default");
ok(-d $obt2->tmpdir,			"default reset with valid");

is($obt2->tmpdir, $dn_reset,		"check default reset");
is($obt1->tmpdir, $obt2->tmpdir,	"default reset matches");


# ---- hometmp -----
isnt($obt1->hometmp, $obt1->tmpdir,			"tmpdir NE hometmp");
is($obt1->default($obt1->hometmp), $obt1->tmpdir,	"default to hometmp");
isnt($obt1->hometmp, $obt1->tmpdir,			"tmpdir EQ hometmp");


__END__

=head1 DESCRIPTION

00_basic.t - test harness for the Batch::Exec::Temp class: basics

=head1 VERSION

_IDE_REVISION_

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

L<perl>, L<Batch::Exec>.

=cut

