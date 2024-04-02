#!/usr/bin/perl
#
# 01_general.t - test harness for the Batch::Exec::Temp module: general
#
use strict;

use Data::Compare;
use Data::Dumper;
use Logfer qw/ :all /;
use Test::More tests => 57;

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
my $ofu1 = Batch::Exec::Temp->new;
isa_ok($ofu1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;


# ---- temporary creation and deletion -----
my $rep=$ofu1->prefix;
my $rex=$ofu1->ext;

my $tf1 = $ofu1->mktmpfile;
isnt( $tf1, "",			"tmpfile not-null");
ok(-f $tf1,			"tmpfile exists");
like( $tf1, qr/$rep/,		"tmpfile prefix");
like( $tf1, qr/$rex$/,		"tmpfile ext");
ok($ofu1->delete($tf1) == 0,	"tmpfile delete");
ok(! -f $tf1,			"tmpfile dne");

my $td1 = $ofu1->mktmpdir;
isnt( $td1, "",			"tmpdir not-null");
ok(-d $td1,			"tmpdir exists");
like( $td1, qr/$rep/,		"tmpdir prefix");
unlike( $td1, qr/$rex$/,	"tmpdir ext");
ok($ofu1->delete($td1) == 0,	"tmpdir delete");
ok(! -d $td1,			"tmpdir dne");


# ---- tmpdir and default -----
my $ofu3 = Fileutils->new;
isa_ok($ofu3, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

ok(-d $ofu3->tmpdir,		"tmpdir default exists");
my $dn_reset = $ofu3->tmpdir;
my $dn_valid = ".";
ok(-d $dn_valid,		"tmpdir override exists");
ok(-d $ofu3->tmpdir($dn_valid),	"tmpdir valid override");
is($ofu3->tmpdir, $dn_valid,	"tmpdir valid matches");

# tmpdir will work even with invalid directory, thus need to use "default"
my $dn_inval = '_$$$_';
ok(! -d $dn_inval,		"tmpdir override DNE");
ok(! -d $ofu3->tmpdir($dn_inval),	"tmpdir invalid override");
is($ofu3->tmpdir, $dn_inval,	"tmpdir invalid matches");

ok(-d $ofu3->default,		"reset default");
isnt($ofu3->default, $dn_inval,	"check default");
ok(-d $ofu3->default($dn_valid),	"override valid default");
is($ofu3->fatal(0), 0,		"set non-fatal");
ok(-d $ofu3->default($dn_inval),	"override invalid default");
ok(-d $ofu3->tmpdir,		"default reset with valid");
is($ofu3->tmpdir, $dn_reset,	"check default reset");
is($ofu3->fatal(1), 1,		"set fatal");


# ---- alternative temporary directory -----
my $ofu2 = Batch::Exec::Temp->new;
isa_ok($ofu2, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

my $dn_tmp = $ofu2->hometmp;
my $dn_dfl = $ofu2->default;
isnt($dn_dfl, $dn_tmp,		"default DNE hometmp");

$ofu2->default($dn_tmp);
$dn_dfl = $ofu2->tmpdir;
is($dn_dfl, $dn_tmp,		"default now hometmp");

my $tf2 = $ofu2->mktmpfile;
ok( -f $tf2,	"mktmpfile hometmp type");

my $td2 = $ofu2->mktmpdir;
ok( -d $td2,	"mktmpdir hometmp type");


# ---- temporary header -----
ok( $ofu1->autoheader(1),	"autoheader on");
ok( ! $ofu2->autoheader,	"autoheader off");

my $tf3 = $ofu1->mktmpfile;
my $tf6 = $ofu1->mktmpfile;
my $tf4 = $ofu2->mktmpfile;
my $tf5 = $ofu2->mktmpfile;
ok( -f $tf3,			"tmp autoon create");
ok( -f $tf4,			"tmp autooff create");
grepper $tf3, 1;
grepper $tf6, 1;
grepper $tf4, 0;
grepper $tf5, 0;


# ---- clean & purge -----
is( $ofu1->clean, 2,		"clean count $cycle"); $cycle++;
is( $ofu2->clean, 4,		"clean count $cycle"); $cycle++;
ok(! -f $tf3,			"check clean $cycle"); $cycle++;
ok(! -f $tf4,			"check clean $cycle"); $cycle++;
ok(! -f $tf5,			"check clean $cycle"); $cycle++;
ok(! -f $tf6,			"check clean $cycle"); $cycle++;


my $tf7 = $ofu1->mktmpfile; $ofu1->mktmpfile; $ofu1->mktmpdir;
my $tf8 = $ofu2->mktmpfile; $ofu2->mktmpfile; $ofu2->mktmpdir;
my $age = 1;
ok( -f $tf7,			"tmpfile 7 exists before purge");
ok( -f $tf8,			"tmpfile 8 exists before purge");

is( $ofu1->age($age), 1,	"purge age 1 wait");
is( $ofu2->age($age), 1,	"purge age 2 wait");

$log->info("sleeping briefly"); sleep($age + 2);

$ofu2->echo(1);
is( $ofu2->purge, 3,		"purge hometmp one");

is( $ofu1->purge, 3,		"purge roottmp one");

ok(! -f $tf7,			"check clean $cycle"); $cycle++;
ok(! -f $tf8,			"check clean $cycle"); $cycle++;


__END__

=head1 DESCRIPTION

Fileutils-3.t - test harness for the Fileutils.pm module: temporary files

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

L<perl>, L<Fileutils>.

=cut

