#!/usr/bin/perl
#
# 01_general.t - test harness for the Batch::Exec::Temp module: general
#
use strict;

use Data::Compare;
use Data::Dumper;
use File::Basename;
use Logfer qw/ :all /;
use Test::More tests => 40;

BEGIN { use_ok('Batch::Exec::Temp') };


# -------- constants --------

# -------- global variables --------
my $log = get_logger(__FILE__);
my $cycle = 1;

# -------- sub-routines --------
sub grepper {
	my $fn = shift;
	my $expected = shift;
	my $re = shift;

	ok(-f $fn, 				"exists grepper $cycle");

	my $desc; if (defined($re)) {
		$desc = "grep $re";
	} else {
		$re = "generated" ;
		$desc = "autohead";
	}

	open(my $fh, "<$fn");

	my $found = 0; while (<$fh>) { $found += grep(/$re/, $_); }

	close($fh);

	is($found, $expected,			"$desc cycle $cycle");

	$cycle++;
}


# -------- main --------
my $ot1 = Batch::Exec::Temp->new('echo' => 1);

isa_ok($ot1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;


# ---- temp file -----
my $rep=$ot1->prefix;
my $rex=$ot1->ext;

my $tf1 = $ot1->file;
isnt($tf1, "",			"temp file not-null");
ok(-f $tf1,			"temp file exists");

like($tf1, qr/$rep/,		"temp file prefix");
like($tf1, qr/$rex$/,		"temp file ext");

ok($ot1->delete($tf1) == 0,	"temp file delete");
ok(! -f $tf1,			"temp file dne");


# ---- temp dir -----
my $td1 = $ot1->folder;
isnt($td1, "",			"temp dir not-null");
ok(-d $td1,			"temp dir exists");

like($td1, qr/$rep/,		"temp dir prefix");
unlike($td1, qr/$rex$/,		"temp dir ext");

ok($ot1->delete($td1) == 0,	"temp dir delete");
ok(! -d $td1,			"temp dir dne");


# ---- alternative temporary directory -----
my $ot2 = Batch::Exec::Temp->new;
isa_ok($ot2, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

my $td2 = $ot2->folder;
ok(-d $td2,			"alt folder exists");

is($ot2->default($td2), $td2,	"default alt folder");

my $tf1a = $ot1->file;
my $tf1b = $ot1->file;

my $tf2a = $ot2->file;
my $tf2b = $ot2->file;

is(dirname($tf1a), dirname($tf1a),	"dirname match base");
is(dirname($tf2a), dirname($tf2a),	"dirname match alt");
isnt(dirname($tf1a), dirname($tf2a),	"dirname mismatch");

for ($tf1a, $tf1b, $tf2a, $tf2b) {

	ok(-f $_,			"temp file exists");
	is($ot2->delete($_), 0,		"delete file [$_]");
}

ok(-d $td2,				"temp dir exists");
is($ot2->delete($td2), 0,		"delete dir");


# ---- temporary header -----
ok($ot1->autoheader(1),			"autoheader on");
my $ah1 = $ot1->file;
grepper $ah1, 1;
is($ot1->delete($ah1), 0,		"delete ahon");


like($ot2->reset, qr/tmp/,		"reset tmp");
is($ot1->tmpdir, $ot2->tmpdir,		"reset match");


my $ah2 = $ot2->file;
ok(! $ot2->autoheader,			"autoheader off");
grepper $ah2, 0;
is($ot2->delete($ah2), 0,		"delete ahoff");


__END__

=head1 DESCRIPTION

01_general.t - test harness for the Batch::Exec::Temp class

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

