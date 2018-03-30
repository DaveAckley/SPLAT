require SPLATtrNodeSectionSplatProgram;

package SPLATtrNodeProgram {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            section0 => $params{section0},
            );
        return bless($self,$class);
    }

    sub decircle {
        my $self = shift;
        my %seenit;

        # recursively blow away everything to 'enhance' gc 
        $self->{section0}->decircle(\%seenit);
    }

    sub isEOF {
        my $text = shift;
        my $ret = length($text) == 1 && substr($text,0,1) eq "\1";
#        print STDERR "isEOF($text)=$ret\n";
        return $ret;
    }

    sub newIfParse {
        my ($class, $s) = @_;
        my $s0 = $s->parseSection0();
        my $sline = $s->peekLine();
        return undef unless isEOF($sline->getText());
        $s->readLine();
        my $self = $class->new($s, 
                               section0 => $s0,
                               sourceLine => $s0->{sourceLine},
            );
        return $self;
    }

    sub analysisPhase {
        my ($self,@args) = @_;
        my $a = $self->{section0}->analysisPhase($self,@args);
        return undef unless defined $a;
        if ($self->{s}->{errorCount} > 0) {
            my $s = "s";
            $s = "" if $self->{s}->{errorCount} == 1;
            SPLATtr::printfFatalError($self->{sourceLine}, 
                                      "%d parsing error$s found",
                                      $self->{s}->{errorCount});
        }
        $self->{section0} = $a;
        return $self;
    }

    sub codegenPhase {
        my ($self,@parents) = @_;
        my $out = $self->{s}->{outHandle};
        my $infile = $self->{s}->{inFileName};
        my $outfile = $self->{s}->{outFileName};
        my $outdir = $self->{s}->{outFileDir};
        my $now = gmtime(time());
        my $user = getpwuid( $< );
        print $out <<EOF;
//ALTERATION IS FUTILE: THIS FILE AUTOMATICALLY GENERATED FROM $infile
//CREATED "$now GMT" BY $0 FOR $user
//BEGIN $outfile (in $outdir)

EOF
        return 0 
          unless $self->{section0}->codegenPhase($self,@parents);
        
        print $out <<EOF;

//END $outfile
EOF
        return 1; 
    }

}

1; # SPLATtrNodeProgram.pm
