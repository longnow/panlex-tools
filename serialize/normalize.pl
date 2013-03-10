# Normalizes expressions in a tagged source file.
# Arguments:
#	0: tag specification (regular expression).
#	1: expression tag.
#	2: column containing expressions to be normalized.
#	3: minimum score (0 or more) a proposed expression must have in order to be accepted
#		outright as an expression. Every proposed expression with a lower (or no) score is
#		to be replaced with the highest-scoring expression sharing its language variety and
#		degradation, if any such expression has a higher score than it.
#	4: minimum score a proposed expression that is not accepted outright as an expression,
#		or its replacement, must have in order to be accepted as an expression.
#	5: variety UID of expressions to be normalized.
#	6: tag of pre-normalized expression.
#	7: if proposed expressions not accepted as expressions and not having replacements accepted
#		as expressions are to be converted to definitions, definition tag, or blank if they
#		are to be converted to pre-normalized expressions.
#	8: regular expression matching the synonym delimiter if each proposed expression containing
#		such a delimiter is to be treated as a list of synonymous proposed expressions and
#		they are to be normalized if and only if all expressions in the list are
#		normalizable, or blank if not.

package PanLex::Serialize::normalize;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use DBI;
# Import the general database-interface module. It imports DBD::Pg for PostgreSQL automatically.

use Unicode::Normalize;
# Import the Unicode normalization module.

sub process {
    my ($in, $out, $tag, $extag, $excol, $minscore, $minscore_repl, $lv, $prenormtag, $dftag, $syndelim) = @_;
    
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

    my (%ex, @line);

    my $lentag = length $extag;
    # Identify the length of the expression tag.

    my @lcvc = split /-/, $lv;
    # Identify the variety's lc and vc.

    $lv = QV("lv ('$lcvc[0]', $lcvc[1])");
    # Identify the variety's ID.

    my $done = 0;
    # Initialize the count of processed lines as 0.

    push @line, <$in>;
    # Identify a list of the lines of the input file.

    chomp @line;
    # Delete their trailing newlines.

    foreach my $line (@line) {
    # For each line:

    	my @col = split /\t/, $line, -1;
    	# Identify its columns.

    	if (length $col[$excol]) {
    	# If the column containing proposed expressions is nonblank:

    		my @seg = ($col[$excol] =~ /($tag.+?(?=$tag|$))/go);
    		# Identify the tagged items, including tags, in it.

    		foreach my $seg (@seg) {
    		# For each of them:

    			if (index($seg, $extag) == 0) {
    			# If it is tagged as an expression:

    				foreach my $ex (PsList($seg, $lentag, $syndelim)) {
    				# For the expression, or for each expression if it is a pseudo-list:

    					$ex{$ex} = '';
    					# Add it to the table of proposed expression texts, if not
    					# already in it.
    				}
    			}
    		}
    	}
    }

    $dbh->do("create temporary table tttd (tt text, td text, uqsum integer)");
    # Create a temporary database table to contain the texts, degradations, and scores
    # of the proposed expressions.

    my $sth = $dbh->prepare("insert into tttd (tt) values (?)");
    # Prepare a statement to insert a text into it.

    foreach my $tt (keys %ex) {
    # For each proposed expression:

    	$sth->execute($tt);
    	# Add its text to the table.
    }

    $dbh->do(
    	'update tttd set uqsum = tbl.uqsum from ('
    		. 'select tttd.tt, sum (uq) as uqsum from tttd, ex, exap, ap '
    		. "where lv = $lv and ex.tt = tttd.tt and exap.ex = ex.ex and ap.ap = exap.ap "
    		. 'group by tttd.tt'
    	. ') as tbl where tttd.tt = tbl.tt'
    );
    # Add the proposed expressions' scores, if any, to the table.

    foreach my $exok (QCs("tt from tttd where uqsum >= $minscore")) {
    # For each proposed expression that has a score and whose score is sufficient for
    # outright acceptance as an expression:

    	$ex{$exok} = 'exok';
    	# Identify it as such.
    }

    $dbh->do("delete from tttd where uqsum >= $minscore");
    # Delete from the table the records of those expressions.

    $dbh->do("update tttd set td = td (tt)");
    # Add to the table the degradations of the texts of the remaining proposed
    # expressions.

    $dbh->do(
    	'create temporary table ttcand as '
    	. 'select distinct tttd.td, ex.tt, sum (uq) as uqsum from tttd, ex, exap, ap '
    	. "where lv = $lv and ex.td = tttd.td and exap.ex = ex.ex and ap.ap = exap.ap "
    	. 'group by tttd.td, ex.tt'
    );
    # Create a temporary database table containing the texts of the expressions in the
    # variety that have those degradations and the sums of those expressions' sources'
    # qualities.

    $dbh->do(
    	'create temporary table tdmax as select td, max (uqsum) as uqmax from ttcand group by td'
    );
    # Create a temporary database table containing the maximum quality sum of each degradation's
    # expressions, if any, in the variety.

    foreach my $exok (QCs(
    	'tttd.tt from tttd, tdmax '
    	. "where tttd.td = tdmax.td and uqsum = uqmax and uqsum >= $minscore_repl"
    )) {
    # For each proposed expression that is a highest-scoring expression in the variety with
    # its degradation and whose score is sufficient for acceptance as an expression:

    	$ex{$exok} = 'exok';
    	# Identify it as such.
    }

    $dbh->do(
    	'delete from tttd using tdmax '
    	. "where tttd.td = tdmax.td and uqsum = uqmax and uqsum >= $minscore_repl"
    );
    # Delete those expressions' records from the database table.

    $dbh->do(
    	'update tttd set td = ttcand.tt, uqsum = uqmax from ttcand, tdmax '
    	. 'where tdmax.td = tttd.td and ttcand.td = tttd.td and ttcand.uqsum = uqmax'
    );
    # Replace the degradations in the table with the texts of the highest-scoring expressions
    # having those degradations, if any, and replace the scores of the replaced expressions
    # with the scores of their replacements.

    my %ttto;

    # Identify a list of references to replaced-replacer pairs for proposed
    # expressions.
    foreach my $ttfmto (QRs("tt, td from tttd where uqsum >= $minscore_repl")) {
    # For each of them:
    	
    	$ttto{$ttfmto->[0]} = $ttfmto->[1];
    	# Add it to a table of replacements.
    }

    foreach my $line (@line) {
    # For each line:

    	my @col = split /\t/, $line, -1;
    	# Identify its columns.

    	if (length $col[$excol]) {
    	# If the column containing proposed expressions is nonblank:

    		my @seg = ($col[$excol] =~ m/($tag.+?(?=$tag|$))/go);
    		# Identify the tagged items, including tags, in it.

    		foreach my $seg (@seg) {
    		# For each item:

    			if (index($seg, $extag) == 0) {
    			# If it is tagged as an expression:

    				my $allok = 1;
    				# Initialize the list's elements as all classifiable as
    				# expressions.

                    my @ex = PsList($seg, $lentag, $syndelim);
                    
    				foreach my $ex (@ex) {
    				# Identify the expression, or a list of the expressions in it if
    				# it is a pseudo-list.

    				# For each of them:

    					unless (
    						(exists $ex{$ex} && $ex{$ex} eq 'exok')
    						|| exists $ttto{$ex}
    					) {
    					# If it is not classifiable as an expression without
    					# replacement or after being replaced:

    						$allok = '';
    						# Identify the list as containing at least 1
    						# expression not classifiable as an expression.

    						last;
    						# Stop checking the expression(s) in the list.
    					}

    				}

    				$seg = '';
    				# Reinitialize the item as blank.

    				if ($allok) {
    				# If all elements of the list are classifiable as expressions with
    				# or without replacement:

    					foreach my $ex (@ex) {
    					# For each of them:

    						if (exists $ex{$ex} && $ex{$ex} eq 'exok') {
    						# If it is classifiable as an expression without
    						# replacement:

    							$seg .= "$extag$ex";
    							# Append it, with an expression tag, to the
    							# item.
    						}

    						else {
    						# Otherwise, i.e. if it is classifiable as an
    						# expression only after replacement:

    							$seg .= "$prenormtag$ex$extag$ttto{$ex}";
    							# Append it, with a pre-normalized
    							# expression tag, and its replacement, with
    							# an expression tag, to the item.
    						}
    					}
    				}

    				else {
    				# Otherwise, i.e. if not all elements of the list are classifiable
    				# as expressions with or without replacement:

    					$seg = join($syndelim, @ex);
    					# Identify the concatenation of the list's elements, with
    					# the specified delimiter if any, i.e. the original item
    					# without its expression tag.

    					if (length $dftag) {
    					# If proposed expressions not classifiable as expressions
    					# are to be converted to definitions:

    						$seg = "$dftag$seg";
    						# Prepend a definition tag to the concatenation.
    					}

    					else {
    					# Otherwise, i.e. if such proposed expressions are not
    					# to be converted to definitions:

    						$seg = "$prenormtag$seg";
    						# Prepend a pre-normalized expression tag to the
    						# concatenation.
    					}
    				}
    			}
    		}

    		$col[$excol] = join('', @seg);
    		# Identify the column with all expression reclassifications.

    	}

    	print $out join("\t", @col), "\n";
    	# Output the line.
    }

    $dbh->disconnect;
    # Disconnect from the database.    
}

#### PsList
# Return a list of items in the specified prefixed pseudo-list.
# Arguments:
#	0: pseudo-list.
#	1: length of its prefix.
#	2: regular expression matching the pseudo-list delimiter, or blank if none.

sub PsList {

	my @ex;

	my $tt  = substr $_[0], $_[1];
	# Identify the specified pseudo-list without its tag.

	if (length $_[2] && $tt =~ /$_[2]/) {
	# If expressions are to be classified as single or pseudo-list
	# and it contains a pseudo-list delimiter:

		@ex = split /$_[2]/, $tt;
		# Identify the expressions in the pseudo-list.
	}

	else {
	# Otherwise, i.e. if expressions are not to be classified as
	# single or pseudo-list or they are but it contains no
	# pseudo-list delimiter:

		@ex = ($tt);
		# Identify a list of the sole expression.
	}

	return @ex;
	# Return a list
}

#### QCs
# Submit the specified SQL query prefixed with "select", get an array of the first or only value
# in each resulting row, and return the resulting array.
# Arguments:
#   0: query after "select".

sub QCs {

	return @{$dbh->selectcol_arrayref("select " . $_[0]) || []};
	# Return the array of the values in the first or only column resulting
	# from the specified query.
}

#### QRs
# Submit the specified SQL query prefixed with "select", get a list of references to rows of
# resulting values, and return the resulting list of row references.
# Arguments:
#   0: query after "select".

sub QRs {

	return @{$dbh->selectall_arrayref("select $_[0]") || []};
	# Return the list of references to the rows resulting from the specified query.
}

#### QV
# Submit the specified SQL query prefixed with "select", get 1 or the first resulting row, get
# the first value of the row, and return the resulting value or a blank if undefined.
# Arguments:
#   0: query after "select".

sub QV {

	my @ret = $dbh->selectrow_array("select $_[0]");
	# Identify the array of values in the first row resulting from the specified query.

    return $ret[0] if @ret && defined $ret[0];
	# If the array isn't empty and its first element is defined,
	# return that value.
	
	return '';
	# Otherwise, return a blank value.
}

1;