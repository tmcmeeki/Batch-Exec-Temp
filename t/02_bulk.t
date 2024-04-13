#!/usr/bin/perl
#
# 02_bulk.t - test harness for the Batch::Exec::Temp module: general
#
use strict;

use Data::Compare;
use Data::Dumper;
use Logfer qw/ :all /;
use Test::More tests => 35;

BEGIN { use_ok('Batch::Exec::Temp') };


# -------- constants --------

# -------- global variables --------
my $log = get_logger(__FILE__);
my $cycle = 1;

# -------- sub-routines --------

# -------- main --------
my $ot1 = Batch::Exec::Temp->new('echo' => 1);

isa_ok($ot1, "Batch::Exec::Temp",	"class check $cycle"); $cycle++;

# ---- clean & purge -----
is($ot1->clean, 2,		"clean count $cycle"); $cycle++;
is($ot2->clean, 4,		"clean count $cycle"); $cycle++;
ok(! -f $tf3,			"check clean $cycle"); $cycle++;
ok(! -f $tf4,			"check clean $cycle"); $cycle++;
ok(! -f $tf5,			"check clean $cycle"); $cycle++;
ok(! -f $tf6,			"check clean $cycle"); $cycle++;


my $tf7 = $ot1->file; $ot1->file; $ot1->folder;
my $tf8 = $ot2->file; $ot2->file; $ot2->folder;
my $age = 1;
ok(-f $tf7,			"temp file 7 exists before purge");
ok(-f $tf8,			"temp file 8 exists before purge");

is($ot1->age($age), 1,	"purge age 1 wait");
is($ot2->age($age), 1,	"purge age 2 wait");

$log->info("sleeping briefly"); sleep($age + 2);

$ot2->echo(1);
is($ot2->purge, 3,		"purge hometmp one");

is($ot1->purge, 3,		"purge roottmp one");

ok(! -f $tf7,			"check clean $cycle"); $cycle++;
ok(! -f $tf8,			"check clean $cycle"); $cycle++;

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

