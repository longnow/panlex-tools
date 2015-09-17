# Uses aspell to spell-check expressions in a tagged source file.
# Requires aspell and the Text::Aspell module.
# Arguments:
#   col:      column containing expressions to be spell-checked.
#   lang:     name of aspell language dictionary.
#   ignore:   regex matching expressions to be ignored in spell checking; or ''
#               (blank) if none. default ''.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.
#   tagre:    regex identifying any tag. default '⫷[a-z0-9:-]+⫸'.

package PanLex::Serialize::spellcheck;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/spellcheck/;

sub spellcheck {
    require Text::Aspell;

    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
        
    my $excol   = $args->{col};
    my $lang    = $args->{lang};
    my $ignore  = $args->{ignore} // '';
    my $extag   = $args->{extag} // '⫷ex⫸';
    my $exptag  = $args->{exptag} // '⫷exp⫸';
    my $tagre   = $args->{tagre} // '⫷[a-z0-9:-]+⫸';

    validate_col($excol);
    
    my $speller = Text::Aspell->new; 
    die "could not access aspell" unless $speller;
    $speller->set_option('lang', $lang);
    $speller->set_option('sug-mode', 'slow');

    my (%ex, %exok);

    my $lentag = length $extag;
    # Identify the length of the expression tag.

    my @line = <$in>;
    # Identify a list of the lines of the input file.

    chomp @line;
    # Delete their trailing newlines.

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        die "column $excol not present in line" unless defined $col[$excol];
        # If the column containing proposed expressions isn’t among them, report the
        # error and quit.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ /($tagre.+?(?=$tagre|$))/g);
            # Identify the tagged items, each item including its tag, in it.

            foreach my $seg (@seg) {
            # For each of the tagged items:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    my $ex = substr $seg, $lentag;

                    if (length $ignore && $ex =~ /$ignore/) {
                    # If the expression is to be ignored:

                        $exok{$ex} = '';
                        # Add it to the table of valid expressions, if not already in it.
                    }

                    else {
                    # Otherwise, i.e. if the expression is not to be ignored:

                        $ex{$ex} = '';
                        # Add it to the table of proposed expressions, if not already in it.
                    }
                }
            }
        }
    }

    foreach my $ex (keys %ex) {
        if ($speller->check($ex)) {
            $exok{$ex} = delete $ex{$ex};
        } else {
            my $sug = ($speller->suggest($ex))[0];

            if (defined $sug) {
                $ex{$ex} = $sug;
            }
        }
    }

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ m/($tagre.+?(?=$tagre|$))/g);
            # Identify the tagged items, including tags, in the column.

            foreach my $seg (@seg) {
            # For each item:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    my $allok = 1;
                    # Initialize the list's elements as all classifiable as
                    # expressions.

                    my $ex = substr $seg, $lentag;

                    if (!exists $exok{$ex} && $ex{$ex} ne '') {
                    # If it is not in the table of accepted expressions and has
                    # a replacement:

                        $seg = "$exptag$ex$extag$ex{$ex}";
                        # Identify its replacement and save it as a pre-normalized
                        # expression.
                    }
                }
            }

            $col[$excol] = join('', @seg);
            # Identify the column with all expression reclassifications.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }

}

1;