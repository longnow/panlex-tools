### Dedup
# Delete duplicate elements in the specified pseudo-list.
# Arguments:
#	0: pseudo-list.
#	1: delimiting non-meta character.

use utf8;
# Make Perl interpret the script as UTF-8. Calling script’s invocation of
# this pragma does not apply to this script, which is imported with a
# “require” statement, i.e. via an “eval `cat dedup.pl`” mechanism.

sub Dedup {

	my ($el, %el);

	my $ret = $_[0];
	# Identify the specified pseudo-list.

	my @el = (split /$_[1]/, $_[0]);
	# Identify its elements.

	foreach $el (@el) {
	# For each of them:

		$el{$el} = '';
		# Add it to the table of elements, if not already in it.

	}

	return (join "$_[1]", (keys %el));
	# Return the specified pseudo-list, without any duplicate elements,
	# in random order.

}	

1;
