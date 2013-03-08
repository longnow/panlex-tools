# Converts a tab-delimited approver file's apostrophes.
# Arguments:
#	0: base of the filename.
#	1: version of the file.
#	2+: specifications (column index and variety UID, colon-delimited) of columns
#		possibly requiring apostrophe normalization.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w apostrophe.pl 'aaa-bbb-Author' 3 '1:eng-000' '2:fra-000'
# The -C63 switch ensures that argument 2 is treated as UTF8-encoded. If it is used within the
# script, it is “too late”.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.

use DBI;
# Import the general database-interface module. It imports DBD::Pg for PostgreSQL automatically.

open DICIN, '<:utf8', "$ARGV[0]-$ARGV[1].txt";
# Open the input file for reading.

open DICOUT, '>:utf8', ("$ARGV[0]-" . ($ARGV[1] + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my $dbh = DBI->connect(
	"dbi:Pg:dbname=plx;host=uf.utilika.org;port=5432", '', '',
	{ (AutoCommit => 0), (pg_enable_utf8 => 1) }
);
# Specify & connect to the PostgreSQL 9.0.1 database “plx”, with AutoCommit off
# and the UTF-8 flag on (without which strings read from the database and split into
# characters are split into bytes rather than Unicode character values. DBI automatically
# issues a begin_work statement, requiring an explicit commit statement before the
# disconnection to avoid an automatic rollback. Username and password will be obtained
# from local (client) environment variables PGUSER and PGPASSWORD, respectively.

my (%apos, $best, @col, @collcvc, $i, @lcvc, $lv, %noncon, @pcol);

$dbh->do (
	'create temporary table apostemp as '
	. "select lv, false as rq, false as ma, false as mtc, ''::text as best from lv order by lv"
);
# Create a temporary database table of apostrophe data.

$dbh->do (
	'update apostemp set rq = true from cp '
	. "where cp.lv = apostemp.lv and c0 <= '02019' and c1 >= '02019'"
);
# Add U+2019 data to it.

$dbh->do (
	'update apostemp set ma = true from cp '
	. "where cp.lv = apostemp.lv and c0 <= '002bc' and c1 >= '002bc'"
);
# Add U+02bc data to it.

$dbh->do (
	'update apostemp set mtc = true from cp '
	. "where cp.lv = apostemp.lv and c0 <= '002bb' and c1 >= '002bb'"
);
# Add U+02bb data to it.

$dbh->do (
	"update apostemp set best = ''' from cp "
	. 'where cp.lv = apostemp.lv and rq and not ma and not mtc'
);
$dbh->do (
	"update apostemp set best = 'ʼ' from cp "
	. 'where cp.lv = apostemp.lv and not rq and not mtc'
);
$dbh->do (
	"update apostemp set best = 'ʻ' from cp "
	. 'where cp.lv = apostemp.lv and not rq and not ma and mtc'
);
$dbh->do (
	"update apostemp set best = 'ʼ' "
	. 'where lv not in (select distinct lv from cp)'
);
# Add data on the best apostrophe to it, making it U+02bc for varieties without any data on
# editor-approved characters.

foreach $i (2 .. $#ARGV) {
# For each column to be processed:

	@collcvc = (split /:/, $ARGV[$i]);
	# Identify its column index and variety UID.

	$pcol[$i] = $collcvc[0];
	# Add its column index to the list of indices of columns to be processed.

	@lcvc = ($collcvc[1] =~ /^([a-z]{3})-(\d{3})$/);
	# Identify the variety's lc and vc.

	$lv = ($dbh->selectrow_array ("select * from lv ('$lcvc[0]', $lcvc[1])"))[0];
	# Identify its lv.

	$best = ($dbh->selectrow_array ("select best from apostemp where lv = $lv"));
	# Identify the normative apostrophe of the variety.

	if ((defined $best) && (length $best)) {
	# If there is one:

		$apos{$collcvc[0]} = $best;
		# Add the index of the column and its variety's normative apostrophe to the table
		# of normative apostrophes.

	}

}

while (<DICIN>) {
# For each line of the input file:

	if ((index $_, "'") > -1) {
	# If it contains any apostrophes:

		@col = (split /\t/, $_, -1);
		# Identify its columns.

		foreach $i (2 .. $#ARGV) {
		# For each column to be processed:

			if ((index $col[$pcol[$i]], "'") > -1) {
			# If it contains any apostrophes:

				if (exists $apos{$pcol[$i]}) {
				# If its variety's apostrophes are convertible:

					$col[$pcol[$i]] =~ s/'/$apos{$pcol[$i]}/g;
					# Convert them.

				}

				else {
				# Otherwise, i.e. if its variety's apostrophes are not convertible:

					$noncon{$pcol[$i]} = '';
					# Add the column to the table of columns containing nonconvertible
					# apostrophes, if not already in it.

				}

			}

		}

		$_ = (join "\t", @col);
		# Identify the modified line.

	}

	print DICOUT;
	# Output the line.

}

if (keys %noncon) {
# If any column contained nonconvertible apostrophes:

	warn (
		'Could not convert apostrophes found in column(s) '
		. (join ', ', (sort {$a <=> $b} (keys %noncon))) . "\n"
	);
	# Report them.

}

$dbh->commit;
# Commit the database transaction.

$dbh->disconnect;
# Disconnect from the database.

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
