package SPLATtrNodePattern {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = bless($ISA[0]->new($splattr, %params),$class);
        %{$self} = (
            %{$self},
            LHS => $params{LHS},
            arrow => $params{arrow},
            RHS => $params{RHS},
            centerX => undef,
            centerY => undef,
            );
        return $self;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;

        ## PHASE 1 of 3: Ensure bounding boxes match
        my $lhs = $self->{LHS};
        my $rhs = $self->{RHS};

        my $sb = $lhs->{sb};

        my ($lh,$lw) = ($lhs->{height},$lhs->{width});
        my ($rh,$rw) = ($rhs->{height},$rhs->{width});
        if ($lh != $rh || $lw != $rw) {
            $self->{s}->printfError($self->{sourceLine},"LHS size ($lh,$lw) doesn't match RHS size ($rh,$rw)");
            return undef;
        }

        ## PHASE 2 of 3: Find unique LHS @
        my ($cx,$cy);
        for (my $j = 0; $j < $lh; ++$j) {
            for (my $i = 0; $i < $lw; ++$i) {
                if ('@' eq $sb->getCharInSB($i + $lhs->{x}, $j + $lhs->{y})) {
                    if (defined($cx)) {
                        $self->{s}->printfError($self->{sourceLine},'Multiple @\'s in pattern LHS');
                        return undef;
                    }
                    ($cx,$cy) = ($i,$j);
                }
            }
        }
        if (!defined($cx)) {
            $self->{s}->printfError($self->{sourceLine},"No @ found in pattern LHS");
            return undef;
        }
        # everybody remembers this fascinating info
        $self->{centerX} = $lhs->{centerX} = $rhs->{centerX} = $cx;
        $self->{centerY} = $lhs->{centerY} = $rhs->{centerY} = $cy;

        ## PHASE 3 of 3: Ensure LHS & RHS shapes match
        my $mismatchCount = 0;
        for (my $j = 0; $j < $lh; ++$j) {
            for (my $i = 0; $i < $lw; ++$i) {
                my $lc = $sb->getCharInSB($i + $lhs->{x}, $j + $lhs->{y});
                my $rc = $sb->getCharInSB($i + $rhs->{x}, $j + $rhs->{y});
                my $ldef = " " ne $lc;
                my $rdef = " " ne $rc;
                if ($ldef != $rdef) {
                    $self->{s}->printfError($self->{sourceLine},"LHS ('$lc') vs RHS ('$rc') shape mismatch at ($i,$j)");
                    ++$mismatchCount;
                }
            }
        }
        return undef if $mismatchCount;
        return $self;
    }

    sub extractKeyCodes {
        my ($self,$ruleset) = @_;
        $self->crash("Bad arg") unless ref($ruleset) eq "SPLATtrNodeSectionSplatRules";
        $self->{LHS}->extractKeyCodes($ruleset) if defined $self->{LHS};
        # keycodes can't go in arrow -- '-' is already taken..
        $self->{RHS}->extractKeyCodes($ruleset) if defined $self->{RHS};
    }

    sub toMultilineString {
        my ($self,$lineprefix) = @_;
        # Umm, barf.
        my $ret = $self->{LHS}->toMultilineString($lineprefix);
        my $lhi = $self->{LHS}->{height};
        my $lmid = int($lhi/2);
        my $lcount = 0;
        # BARF barf.
        $ret =~ s/\n/($lcount++ == $lmid)?" -> \n":"    \n"/ge;

        # barf barf barf.
        $ret = $self->{RHS}->toMultilineString(split("\n",$ret));

        # Come again, have a nice day.
        return $ret;
    }

    sub generateEvalString {
        my ($self) = @_;
        my $ret = $self->{LHS}->generateEvalString(1);
        $ret .= "\\377";
        $ret .= $self->{RHS}->generateEvalString(0);
        $ret .= "\\376";
        return $ret;
    }

}

1; # SPLATtrNodePattern.pm
