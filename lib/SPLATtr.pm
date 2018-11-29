use strict;
use warnings;
use diagnostics;
use Carp;

require SPLATSourceLine;
require SPLATUrSelf;
require SPLATtrNode;
require SPLATtrNodeBlob;
require SPLATtrNodeKeySet;
require SPLATtrNodeMethodGetClass;
require SPLATtrNodePattern;
require SPLATtrNodeProgram;
require SPLATtrNodeSection;
require SPLATtrNodeSectionSplatClass;
require SPLATtrNodeSectionSplatDataMembers;
require SPLATtrNodeSectionSplatMethods;
require SPLATtrNodeSectionSplatProgram;
require SPLATtrNodeSectionSplatRules;
require SPLATtrNodeSentence;
require SPLATtrNodeSententialGroup;
require SPLATtrNodeUnit;
require SPLATtrNodeUnitSpatialBlock;

### VERSION HISTORY
#
# 1.002 2018/11/07 First released version
#
# 1.001 Primordial soup
#
###

# SPLAT translator
package SPLATtr {
    use parent "SPLATUrSelf";
    our @ISA;

    use File::Basename;

    sub new {
        my ($class, $inFileName) = @_;
        my $self = $ISA[0]->new();
        $self->{s} = $self; # CLOSING THE LOOP BY HAND
        bless $self, $class;

        $self->crash unless defined $inFileName;

        my @suffixList = ".splat";
        my ($stemName,$path,$suffix) = fileparse($inFileName,@suffixList);
        usageDie("Not a .splat file: '$inFileName'")
            unless $suffix eq ".splat";

        $path .= "/" unless $path =~ m!/$!;
        my $outdir = "$path.splatgen";
        if (-d $outdir) {
            # Can't do this with multisplatfile builds!
            # # Half-hearted try to clean up
            # my @ulams = glob "$outdir/*.ulam";
            # unlink @ulams if scalar(@ulams);
        } else {
            mkdir $outdir or usageDie("Cannot create working directory '$outdir': $!");
        }
        %{$self} = (
            %{$self},
            className => $stemName,
            inFileName => $inFileName,
            outFileName => "$stemName.ulam",
            outFileDir => "$outdir",
            outFilePath => "$outdir/$stemName.ulam",
            pushedLine => undef,
            inLine => undef,
            inLineNo => 0,
            errorCount => 0,
            warnCount => 0,
            section0 => undef,
            );

        $self->openFiles();

        return $self;
    }

    sub parseSection0 {
        my $self = shift;
        my $s0 = SPLATtrNodeSectionSplatProgram->
            new($self, 
                sectionLevel=>0,
                sectionDescriptor=>"splat file ".$self->{inFileName});

        $s0->{sourceLine} = $self->{s}->peekLine();
        $s0->parseSectionBody();
        return $s0;
    }

    sub decircle {
        my $self = shift;
        
    }

    sub usageDie {
        my ($fmt, @args) = @_;
        my $msg = sprintf $fmt,@args;
        print STDERR "Error: $msg\n";
        print STDERR "Usage: $0 [OPTIONS] INFILE.splat..\n";
        print STDERR "'$0 -h' for help on [OPTIONS]\n";
        exit 2;
    }

    sub openFiles {
        my $self = shift;
        open(my $inhandle, "<", $self->{inFileName}) 
            or usageDie "Can't read '".$self->{inFileName}."': $!\n";
        $self->{inHandle} = $inhandle;

        open(my $outhandle, ">", $self->{outFilePath}) 
            or die "Can't write '".$self->{outFilePath}."': $!\n";
        $self->{outHandle} = $outhandle;
    }

    sub unreadLine {
        my $self = shift;
        $self->crash("Nothing read") unless defined $self->{inLine};
        $self->crash("Already pushed") if defined $self->{pushedSourceLine};
        $self->{pushedSourceLine} = $self->{inLine};
        $self->{inLine} = undef;
    }

    sub peekLine {
        my $self = shift;
        my $sline = $self->readLine();
        $self->unreadLine();
        return $sline;
    }

    sub isCommentLine {
        my ($self,$text) = @_;
        return $text =~ /^#/;
    }

    sub readLine {
        my $self = shift;
        my $sline;
        if (defined $self->{pushedSourceLine}) {
            $sline = $self->{pushedSourceLine};
            $self->{pushedSourceLine} = undef;
        } else {
            my $text;
            while ($text = readline($self->{inHandle})) {
                ++$self->{inLineNo};
#                print STDERR "TEXT($text/$self->{inLineNo})\n";
                last unless $self->isCommentLine($text);
            }
            if (!defined($text)) {
                # EOF handling.  Create a special OoB source line for parsing to see
                $sline = SPLATSourceLine->new($self, $self->{inFileName}, "\n", $self->{inLineNo});
                $sline->{line} = "\1";  # ^A (anything but ^Z)
            } else {
                chomp($text);
                $text .= "\n";
                $sline = SPLATSourceLine->new($self, $self->{inFileName}, $text, $self->{inLineNo});
            }
        }
        $self->{inLine} = $sline;
#        print STDERR $sline->getLabeledLine()."\n";
        return $self->{inLine};
    }

    sub dump {
        my ($self, $maxdepth, $handle) = @_;
        dumpOther($self, 0, $maxdepth, $handle);
    }
    sub dumpThis {
        my ($self, $hash, $depth, $maxdepth, $handle) = @_;
        dumpOther($hash, $depth, $maxdepth, $handle);
    }

    sub dumpOther {
        my ($thing, $depth, $maxdepth, $handle, $suppressions) = @_;
        return if $depth >= $maxdepth;
        $handle = *STDERR unless defined $handle;
        my $ttype = ref $thing;
        if ($ttype eq "HASH" or $ttype =~ /^SPLAT/) {
            print $handle ("  "x$depth)."$thing\{\n";
            dumpHash($thing, $depth+1, $maxdepth, $handle, 
                     { Type_SPLATtr => 1,
                       Field_fileName => 1,
                     });
        } elsif ($ttype eq "ARRAY") {
            print $handle ("  "x$depth)."\[\n";
            foreach my $elt (@{$thing}) {
                dumpOther($elt, $depth+1, $maxdepth, $handle, $suppressions);
            }
        } else {
            print $handle ("  "x$depth)."$thing\n";
            return;
        }
        print $handle ("  "x$depth)."\}\n";
    }

    sub printfError {
        my ($self, $line, $fmt, @args) = @_;
#        print STDERR "GAH $line\n;";
        printf STDERR $line->getLocation().": ERROR: $fmt\n",@args;
        if (++$self->{errorCount} > 100) {
            printfFatalError($line, "Too many errors, giving up");
        }
    }

    sub printfWarning {
        my ($self, $line, $fmt, @args) = @_;
        printf STDERR $line->getLocation().": WARNING: $fmt\n",@args;
        ++$self->{warnCount};
    }

    #### STATIC METHODS

    sub printfFatalError {
        my ($line, $fmt, @args) = @_;
        printf STDERR $line->getLocation().": FATAL: $fmt\n",@args;
        exit 3;
    }

    my %sitenums = (
        "0,0" =>    0,
        "-1,0" =>   1,
        "0,-1" =>   2,
        "0,1" =>    3,
        "1,0" =>    4,
        "-1,-1" =>  5,
        "-1,1" =>   6,
        "1,-1" =>   7,
        "1,1" =>    8,
        "-2,0" =>   9,
        "0,-2" =>  10,
        "0,2" =>   11,
        "2,0" =>   12,
        "-2,-1" => 13,
        "-2,1" =>  14,
        "-1,-2" => 15,
        "-1,2" =>  16,
        "1,-2" =>  17,
        "1,2" =>   18,
        "2,-1" =>  19,
        "2,1" =>   20,
        "-3,0" =>  21,
        "0,-3" =>  22,
        "0,3" =>   23,
        "3,0" =>   24,
        "-2,-2" => 25,
        "-2,2" =>  26,
        "2,-2" =>  27,
        "2,2" =>   28,
        "-3,-1" => 29,
        "-3,1" =>  30,
        "-1,-3" => 31,
        "-1,3" =>  32,
        "1,-3" =>  33,
        "1,3" =>   34,
        "3,-1" =>  35,
        "3,1" =>   36,
        "-4,0" =>  37,
        "0,-4" =>  38,
        "0,4" =>   39,
        "4,0" =>   40,
        );

    my @siteNumToCoord;
    foreach my $c (keys %sitenums) {
        my $val = $sitenums{$c};
        $siteNumToCoord[$val] = $c;
    }
    scalar(@siteNumToCoord) or SPLATtr::crash("Init failure");
    foreach my $sn (@siteNumToCoord) {
        defined $sn or SPLATtr::crash("Init failure");
    }

    sub coordFromSiteNum {
        my ($sn) = @_;
        my $c = $siteNumToCoord[$sn];
        defined $c or SPLATtr::crash("Bad sn $sn");
        return split(",",$c);
    }

    sub siteNumFromCoord {
        my ($x,$y) = @_;
        my $str = "$x,$y";
        return $sitenums{$str};
    }

    sub prefixIndent {
        my ($prefix,$multiline) = @_;
        my $ret = $prefix.$multiline;
        $ret =~ s/\n(.)/\n$prefix$1/g;
        chomp $ret;
        $ret .= "\n";
        return $ret;
    }

    sub dumpHash {
        my ($href, $depth, $maxdepth, $handle, $suppressions) = @_;
        my $indent = "  "x$depth;
        for my $key (sort keys %{$href}) {
            next if $suppressions->{"Field_$key"};
            my $val = $href->{$key};
            my $type = ref $val;
            if ($type eq "HASH" or $type =~ /^SPLAT/) {
                if (!$suppressions->{"Type_$type"}) {
                    print $handle "$indent$key->$type\n";
                    dumpHash($val, $depth+1, $maxdepth, $handle, $suppressions) 
                        if $depth < $maxdepth;
                }
            } elsif ($type eq "ARRAY") {
                if ($depth < $maxdepth) {
                    print $handle "$indent$key=[\n";
                    foreach my $elt (@{$val}) {
                        dumpOther($elt, $depth+1, $maxdepth, $handle, $suppressions);
                    }
                    print $handle "$indent]\n";
                } else {
                    print $handle "$indent$key=>[@{$val}]\n";
                }
            } else {
                if (defined $val) {
                    print $handle "$indent$key=$val\n" ;
                } else {
                    print $handle "$indent$key=(undef)\n" ;
                }
            }
        }
    }

    sub legalUlamType {
        my $string = shift;
        SPLATUrSelf::crash("Missing arg") unless defined $string;
        return $string =~ /^[A-Z][_a-zA-Z0-9]*$/;
    }

    sub legalUlamVar {
        my $string = shift;
        SPLATUrSelf::crash("Missing arg") unless defined $string;
        return $string =~ /^[a-z][_a-zA-Z0-9]*$/;
    }


    sub toLex {
        my $num = shift;
        my $len = length($num);
        return $len.$num if $len < 9;
        return "9".toLex($len).$num;
    }

    sub getLexLength {
        my $lexref = shift;
        if ($$lexref =~ s/^([1-8])//) {
            return $1;
        }
        printfFatalError("Illegal lex input '$$lexref'") unless  $$lexref =~ s/^9//;
        my $len = getLexLength($lexref);
        printfFatalError("Illegal lex length '$len' in '$$lexref'") unless length($$lexref) >= $len;
        return substr $$lexref,0,$len,"";
    }

    sub fromLex {
        my $lex = shift;
        my $orig = $lex;
        my $len = getLexLength(\$lex);
        printfFatalError("Bad size lex input '$orig'") if length($lex) != $len;
        return $lex;
    }

    sub isSubtypeOf {
        use Scalar::Util;

        my ($thing,$class) = @_;
        return 0 unless defined $thing;
        my $ret = 0;
        $ret = $thing->isa($class)
            if Scalar::Util::blessed $thing;
        return $ret;
    }

    1;
}

