# Converts a tab-delimited source file's apostrophes.
# Arguments:
#	0+: specifications (column index and variety UID, colon-delimited) of columns
#		possibly requiring apostrophe normalization.

package PanLex::Serialize::apostrophe;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use DBI;
# Import the general database-interface module. It imports DBD::Pg for PostgreSQL automatically.

sub process {
    my ($in, $out, @args) = @_;
    
    my $dbh = DBI->connect(
    	"dbi:Pg:dbname=plx;host=db.panlex.org;port=5432", '', '',
    	{ (AutoCommit => 0), (pg_enable_utf8 => 1) }
    );
    # Specify & connect to the PostgreSQL database “plx”, with AutoCommit off
    # and the UTF-8 flag on (without which strings read from the database and split into
    # characters are split into bytes rather than Unicode character values). DBI automatically
    # issues a begin_work statement, requiring an explicit commit statement before the
    # disconnection to avoid an automatic rollback. Username and password will be obtained
    # from local (client) environment variables PGUSER and PGPASSWORD, respectively.

    $dbh->do(
    	'create temporary table apostemp as '
    	. "select lv, false as rq, false as ma, false as mtc, ''::text as best from lv order by lv"
    );
    # Create a temporary database table of apostrophe data.

    $dbh->do(
    	'update apostemp set rq = true from cp '
    	. "where cp.lv = apostemp.lv and c0 <= '02019' and c1 >= '02019'"
    );
    # Add U+2019 data to it.

    $dbh->do(
    	'update apostemp set ma = true from cp '
    	. "where cp.lv = apostemp.lv and c0 <= '002bc' and c1 >= '002bc'"
    );
    # Add U+02bc data to it.

    $dbh->do(
    	'update apostemp set mtc = true from cp '
    	. "where cp.lv = apostemp.lv and c0 <= '002bb' and c1 >= '002bb'"
    );
    # Add U+02bb data to it.

    $dbh->do(
    	"update apostemp set best = ''' from cp "
    	. 'where cp.lv = apostemp.lv and rq and not ma and not mtc'
    );
    $dbh->do(
    	"update apostemp set best = 'ʼ' from cp "
    	. 'where cp.lv = apostemp.lv and not rq and not mtc'
    );
    $dbh->do(
    	"update apostemp set best = 'ʻ' from cp "
    	. 'where cp.lv = apostemp.lv and not rq and not ma and mtc'
    );
    $dbh->do(
    	"update apostemp set best = 'ʼ' "
    	. 'where lv not in (select distinct lv from cp)'
    );
    # Add data on the best apostrophe to it, making it U+02bc for varieties without any data on
    # editor-approved characters.

    my (%apos, %noncon, @pcol);

    for (my $i = 0; $i < @args; $i++) {
    # For each column to be processed:

    	my @collcvc = split /:/, $args[$i];
    	# Identify its column index and variety UID.

    	$pcol[$i] = $collcvc[0];
    	# Add its column index to the list of indices of columns to be processed.

    	my @lcvc = ($collcvc[1] =~ /^([a-z]{3})-(\d{3})$/);
    	# Identify the variety's lc and vc.

    	my $lv = ($dbh->selectrow_array("select * from lv ('$lcvc[0]', $lcvc[1])"))[0];
    	# Identify its lv.

    	my $best = ($dbh->selectrow_array("select best from apostemp where lv = $lv"));
    	# Identify the normative apostrophe of the variety.

    	if (defined $best && length $best) {
    	# If there is one:

    		$apos{$collcvc[0]} = $best;
    		# Add the index of the column and its variety's normative apostrophe to the table
    		# of normative apostrophes.
    	}
    }

    while (<$in>) {
    # For each line of the input file:
        
    	if (index($_, "'") > -1) {
    	# If it contains any apostrophes:

    		my @col = split /\t/, $_, -1;
    		# Identify its columns.

            foreach my $i (@pcol) {
    		# For each column to be processed:

    			if (index($col[$i], "'") > -1) {
    			# If it contains any apostrophes:

    				if (exists $apos{$i}) {
    				# If its variety's apostrophes are convertible:

    					$col[$i] =~ s/'/$apos{$i}/g;
    					# Convert them.
    				}

    				else {
    				# Otherwise, i.e. if its variety's apostrophes are not convertible:

    					$noncon{$i} = '';
    					# Add the column to the table of columns containing nonconvertible
    					# apostrophes, if not already in it.
    				}
    			}
    		}

    		$_ = join "\t", @col;
    		# Save the modified line.
    	}

    	print $out;
    	# Output the line.
    }

    if (keys %noncon) {
    # If any column contained nonconvertible apostrophes:

    	warn (
    		'Could not convert apostrophes found in column(s) '
    		. join(', ', sort { $a <=> $b } keys %noncon) . "\n"
    	);
    	# Report them.
    }

    $dbh->disconnect;
    # Disconnect from the database.    
}

1;