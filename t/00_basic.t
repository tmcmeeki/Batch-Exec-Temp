#!/usr/bin/perl
#
# 00_basic.t - test harness for the Batch::Exec::Temp class: basics
#
use strict;

use Data::Dumper;
use File::Spec;
use Logfer qw/ :all /;
#use Log::Log4perl qw/ :easy /;
use Test::More tests => 116;

BEGIN { use_ok('Batch::Exec::Temp') };


# -------- constants --------


# -------- global variables --------
my $log = get_logger(__FILE__);

my $cycle = 1;


# -------- subroutines --------


# -------- main --------
my $ot1 = Batch::Exec::Temp->new;
isa_ok($ot1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

my $ot2 = Batch::Exec::Temp->new(echo => 1, fatal => 0);
isa_ok($ot2, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;


# -------- simple attributes --------
my @attr = $ot1->Attributes;
my $attrs = 21;
is(scalar(@attr), $attrs,		"class attributes");
is(shift @attr, "Batch::Exec::Temp",	"class okay");

for my $attr (@attr) {

	my $dfl = $ot1->$attr;

	my ($set, $type); if (defined $dfl && $dfl =~ /^[\-\d\.]+$/) {
		$set = -1.1;
		$type = "f`";
	} else {
		$set = "_dummy_";
		$type = "s";
	}

	is($ot1->$attr($set), $set,	"$attr set cycle $cycle");
	isnt($ot1->$attr, $dfl,	"$attr check");

	$log->debug(sprintf "attr [$attr]=%s", $ot1->$attr);

	if ($type eq "s") {
		my $ck = (defined $dfl) ? $dfl : "_null_";

		ok($ot1->$attr ne $ck,	"$attr string");
	} else {
		ok($ot1->$attr < 0,	"$attr number");
	}
	is($ot1->$attr($dfl), $dfl,	"$attr reset");

        $cycle++;
}


# -------- Inherit --------
is($ot1->Inherit($ot2), $attrs - 1,	"inherit same attribute count");


# ---- miscellaneous defaults -----
ok($ot1->age > 0,		"age default");
like($ot1->ext, qr/tmp/,	"ext default");
is($ot1->retain, 0,		"retain default");


# ---- tmpdir -----
my $dn_reset = $ot2->tmpdir;
my $dn_valid = ".";
my $dn_inval = '_$$$_';

ok(-d $ot2->tmpdir,		"tmpdir default exists");
ok(-d $dn_valid,		"tmpdir override exists");

ok($ot2->tmpdir($dn_valid),	"tmpdir is read-only");


# ---- reset -----
is($ot1->reset, $dn_reset,		"reset to default");
is($ot1->reset, $ot2->reset,		"reset matches");


# ---- default -----
ok(-d $ot2->default,			"default resets default");
isnt($ot2->default, $dn_inval,		"check default");

ok(-d $ot2->default($dn_valid),	"override valid default");
ok(-d $ot2->default($dn_inval),	"override invalid default");
ok(-d $ot2->tmpdir,			"default reset with valid");

is($ot2->tmpdir, $dn_reset,		"check default reset");
is($ot1->tmpdir, $ot2->tmpdir,	"default reset matches");


# ---- All and Extant before -----
is(scalar($ot1->All), 0,		"All zero");
is(scalar($ot1->Extant), 0,		"Extant zero");


# ---- register -----
my @match = File::Spec->splitdir($ot1->tmpdir);
my $redm = pop @match;

my $pn = $ot1->register('f');
like($pn, qr/$redm/,		"register file");
ok(-f $pn,			"file exists");
is($ot1->delete($pn), 0,	"file removed");

$pn = $ot1->register('d');
like($pn, qr/$redm/,		"register folder");
ok(-d $pn,			"folder exists");

SKIP: {
	skip "invalid register option", 1;

	my $pn = $ot1->register();
}

# ---- All and Extant after -----
is(scalar($ot1->All), 2,		"All nonzero");
is(scalar($ot1->Extant), 1,		"Extant nonzero");

#$log->debug(sprintf "ot1 [%s]", Dumper($ot1));


# ---- count -----
is($ot1->count, 1,		"count");

is($ot1->delete($pn), 0,	"folder removed");

is(scalar($ot1->All), 2,	"All still nonzero");
is(scalar($ot1->Extant), 0,	"Extant zero again");
is($ot1->count, 0,		"final count zero");

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

