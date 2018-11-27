package SPLATtrNodeBlob {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = bless($ISA[0]->new($splattr, %params),$class);
        %{$self} = (
            %{$self},
            sb => $params{sb}, # circular link; oh well; gc is for wusses
            x => $params{x},
            y => $params{y},
            width => $params{width},
            height => $params{height},
            tag => $params{tag},
            centerX => undef,
            centerY => undef,
            );
        return $self;
    }

    sub decircle {
        my ($self) = @_;
        $self->{sb} = undef; # kill circular link
    }

    sub toMultilineString {
        my ($self,@prefices) = @_;
        my $sb = $self->{sb};
        $self->crash("No sb") unless ref($sb) eq "SPLATtrNodeUnitSpatialBlock";
        my $lineprefix = "";
        my $ret = "";
        for (my $j = 0; $j < $self->{height}; ++$j) {
            if (scalar(@prefices) > 0) {
                $lineprefix = shift @prefices;
            }
            $ret .= $lineprefix;
            for (my $i = 0; $i < $self->{width}; ++$i) {
                $ret .= $sb->getCharInSB($i + $self->{x}, $j + $self->{y});
            }
            $ret .= "\n";
        }
        return $ret;
    }

    sub generateEvalString {
        my ($self,$LHS) = @_;
        my $sb = $self->{sb};
        $self->crash("No sb") unless ref($sb) eq "SPLATtrNodeUnitSpatialBlock";

        my ($cx,$cy) = ($self->{centerX},$self->{centerY});
        my $ret = "";

        # Visit (defined) sites in standard sitenum index order
        for (my $sn = 0; $sn < 41; ++$sn) {
            my ($rx,$ry) = SPLATtr::coordFromSiteNum($sn);
            my ($bx,$by) = ($rx + $cx, $ry + $cy);
            next if $bx < 0 or $by < 0 or $bx >= $self->{width} or $by >= $self->{height};
            my ($ax,$ay) = ($bx + $self->{x}, $by + $self->{y});
            my $ch = $sb->getCharInSB($ax,$ay);
            next if $ch eq " ";

            # Optimization: Don't even visit '.'s on the RHS.
            # This speeds things up a bit but means that a 'change
            # .' declaration is impotent (and should at least be
            # warned about, but we don't, at present.)
            next if !$LHS && $ch eq ".";  

            $ret .= sprintf("\\%03o%s",$sn,$ch);
        }
        return $ret;
    }

    sub extractKeyCodes {
        my ($self,$ruleset) = @_;
        my $sb = $self->{sb};
        $self->crash("Bad arg") unless ref($ruleset) eq "SPLATtrNodeSectionSplatRules";
        $self->crash("No sb") unless ref($sb) eq "SPLATtrNodeUnitSpatialBlock";
        for (my $j = 0; $j < $self->{height}; ++$j) {
            for (my $i = 0; $i < $self->{width}; ++$i) {
                my $ch = $sb->getCharInSB($i + $self->{x}, $j + $self->{y});
                next if $ch eq ' ';
                if (SPLATtrNodeKeySet::isKeyCode($ch)) {
                    $ruleset->getKeySet($ch); # just to ensure it exists
                } else {
                    $self->{s}->printfError($self->{sourceLine},"Illegal keycode '$ch' in pattern");
                }
            }
        }
    }
}

1; # SPLATtrNodeBlob.pm
