# Spell-checks expressions in a tagged source file.
# aspell requires Text::Aspell; hunspell requires Text::Hunspell.
# Arguments:
#   col:      column containing expressions to be spell-checked.
#   engine:   spell-check engine to use ('aspell' or 'hunspell').
#   dict:     dictionary to use. for aspell, this is one of the names returned
#               by `aspell dicts`. for hunspell, this is the full path to the 
#               dictionary file, excluding the '.aff' or '.dic' extension.
#   ignore:   regex matching expressions to be ignored in spell checking; or ''
#               (blank) if none. default ''.
#   failtag:  tag with which to retag proposed expressions not accepted as 
#               expressions; '' (blank) if they are to be converted to 
#               pre-normalized expressions. default '⫷df⫸'.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.
#   tagre:    regex identifying any tag. default '⫷[a-z0-9:-]+⫸'.

package PanLex::Serialize::spellcheck;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw(spellcheck);

sub spellcheck {
    my ($in, $out, $args) = @_;
        
    my $excol   = $args->{col};
    my $engine  = $args->{engine};
    my $dict    = $args->{dict};
    my $ignore  = $args->{ignore} // '';
    my $failtag = $args->{failtag} // '⫷df⫸';
    my $extag   = $args->{extag} // '⫷ex⫸';
    my $exptag  = $args->{exptag} // '⫷exp⫸';
    my $tagre   = $args->{tagre} // '⫷[a-z0-9:-]+⫸';

    $failtag = $exptag if $failtag eq '';

    validate_col($excol);
    
    my $speller;

    if ($engine eq 'aspell') {
        require Text::Aspell;
        
        $speller = Text::Aspell->new; 
        die "could not access aspell" unless $speller;

        $speller->set_option('lang', $dict);
        $speller->set_option('sug-mode', 'slow');
    } elsif ($engine eq 'hunspell') {
        require Text::Hunspell;

        $speller = Text::Hunspell->new("${dict}.aff", "${dict}.dic");
        die "could not access hunspell" unless $speller;
    } else {
        die "unknown engine: $engine";
    }

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

    EX: foreach my $ex (keys %ex) {
        if ($speller->check($ex)) {
            $exok{$ex} = delete $ex{$ex};
        } else {
            my @sugwords;

            foreach my $word (split(' ', $ex)) {
                if (!$speller->check($word)) {
                    $word = ($speller->suggest($word))[0];

                    if (!defined $word) {
                        delete $ex{$ex};
                        next EX;
                    }
                }

                push @sugwords, $word;
            }

            my $sug = join(' ', @sugwords);

            if ($ex eq $sug) {
                $exok{$ex} = delete $ex{$ex};
            } else {
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

                    my $ex = substr $seg, $lentag;

                    if (!exists $exok{$ex}) {
                    # If it is not in the table of accepted expressions:

                        if (exists $ex{$ex}) {
                        # If it has a replacement:

                            $seg = "$exptag$ex$extag$ex{$ex}";
                            # Identify its replacement and save it as a pre-normalized
                            # expression.
                        } else {
                        # Otherwise, i.e. if it has no replacement:

                            $seg = "$failtag$ex";
                            # Retag it as having failed spell-check.

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

}

1;