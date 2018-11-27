package SPLATtrNodeUnitSpatialBlock {
    use parent "SPLATtrNodeUnit";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = bless($ISA[0]->new($splattr, %params),$class);
        %{$self} = (
            %{$self},
            analyzed => 0,
            spatialLines => [],
            blobs => [],
            patterns => [],
            width => undef,
            height => undef,
            );

        return $self;
    }

    sub extractKeyCodes {
        my ($self,$ruleset) = @_;
        $self->crash("Bad arg") unless ref($ruleset) eq "SPLATtrNodeSectionSplatRules";
        $self->crash("Unanalyzed spatial block") unless $self->{analyzed};
        foreach my $pattern (@{$self->{patterns}}) {
            $pattern->extractKeyCodes($ruleset);
        }
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        die if $self->{analyzed};
        $self->findPatternsInSpatialBlock($self,@parents);
        if (scalar(@{$self->{patterns}}) > 0) {
            my $sclass = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
            my $rsect = $self->getClassFromParents("SPLATtrNodeSectionSplatRules",@parents);
            if (!defined($rsect)) {
                $self->{s}->printfError($self->{sourceLine},"Non-empty spatial block in top-level section (Missing '== Rules'?)");
                return undef;
            }

            if (!defined($sclass)) {
                $self->{s}->printfError($self->{sourceLine},"Non-empty spatial block outside of splat class");
                return undef;
            }
            $self->{className} = $sclass->{className};
            $self->crash("Missing class name") unless defined $self->{className};

            for (my $p = 0; $p < scalar(@{$self->{patterns}}); ++$p) {
                my $pat = $self->{patterns}->[$p];
                $pat = $pat->analysisPhase($self,@parents);
                return undef unless defined $pat;
                $self->{patterns}->[$p] = $pat;
            }
        }

        $self->{analyzed} = 1;
        return $self;
    }
    sub isSpatialLine {
        my ($self,$text) = @_;
        my $is = $text =~ /^( .*|)$/;
        return $is; # A leading space, and totally nothing, are spatial..
    }


    sub newIfParse {
        my ($class, $s) = @_;
        my $self = $class->new($s);
        # For now, all we want is more than 0 spatial lines
        while (my $sline = $s->peekLine()) {
            last unless $self->isSpatialLine($sline->getText());
            $self->{sourceLine} = $sline   # First line represents the block
                if scalar(@{$self->{spatialLines}}) == 0;
            push @{$self->{spatialLines}}, $s->readLine();
        }
        return $self if (scalar(@{$self->{spatialLines}}) > 0);

        # Poop.
        return undef;
    }


    ## Ported from splatr1.pl
    sub computeSBSize {
        my ($self) = @_;
        my $maxl = -1;
        my @lines = @{$self->{spatialLines}};
        for my $sline (@lines) {
            my $line = $sline->getText();
            my $len = length($line);
            $maxl = $len if $maxl < $len;
        }
        $self->{width} = $maxl;
        $self->{height} = scalar(@lines);
    }

    ## Ported from splatr1.pl
    sub getCharInSB {
        my ($self,$x,$y) = @_;
        return " " if $x < 0 || $y < 0;
        return " " if $y >= $self->{height};
        my $line = $self->{spatialLines}->[$y]->getText();
        die "Nothing at $self line $y" unless defined $line;
        return " " if $x >= length($line);
        return substr($line,$x,1);
    }

    ## Ported from splatr1.pl
    sub notAllBlank {
        my ($self,$minx,$miny,$maxx,$maxy) = @_;
        for (my $y = $miny; $y <= $maxy; ++$y) {
            for (my $x = $minx; $x <= $maxx; ++$x) {
                return 1 unless $self->getCharInSB($x,$y) eq " ";
            }
        }
        return 0;
    }

    ## Ported from splatr1.pl
    sub isEmptySB {
        my ($self) = @_;
        my ($wid,$hei) = $self->getSBSize();
        return !$self->notAllBlank(0,0,$wid-1,$hei-1);
    }

    ## Ported from splatr1.pl
    sub getLineInSB {
        my ($self, $y) = @_;
        die "No such line $y" if $y >= $self->{height};
        return $self->{spatialLines}->[$y]->getText();
    }

    ## Ported from splatr1.pl
    sub getSBSize {
        my $self = shift;
        return ($self->{width}, $self->{height});
    }

    ## Ported from splatr1.pl
    # Return coord of next possible pattern pointer arrowhead starting to
    # the right or below of ($sx,$sy), if any, or undef if no more.
    sub nextArrowheadInSB {
        my ($self,$sx,$sy) = @_;
        my ($wid,$hei) = $self->getSBSize();
        
        my $ix = $sx + 1;
        for (my $r = $sy; $r < $hei; ++$r) {
            for (my $c = $ix; $c < $wid; ++$c) {
                return ($c,$r) if $self->getCharInSB($c,$r) eq ">";
            }
            $ix = 0;
        }
        return undef;
    }

    ## Ported from splatr1.pl
    # Return the next pattern pointer starting to the right or below of
    # ($sx,$sy) and the $x and $y coordinates of its arrowhead.  If no
    # more pattern pointers, return undef.
    sub nextPatternPointerInSB {
        my ($self,$sx,$sy) = @_;
        my ($nx,$ny) = $self->nextArrowheadInSB($sx,$sy);
        return undef unless defined $nx;
        if ($nx == 0) {
            $self->{s}->printfError($self->{sourceLine},
                                    "Illegal pattern pointer position $nx");
        } else {
            my ($nextch,$minx);
            for ($minx = $nx; $minx >= 0; --$minx) {
                $nextch = $self->getCharInSB($minx-1,$ny);
                if ($nextch ne " ") { next; }
                last;
            }
            if ($minx < 0 || $nextch ne " ") {
                $self->{s}->printfError($self->{sourceLine},
                                        "Illegal pattern pointer at ($nx,$ny)");
            } else {
                my $wid = $nx - $minx + 1;
                return (substr($self->getLineInSB($ny),$minx, $wid),
                        $nx, $ny, $wid, 1);
            }
        }
        return undef;
    }

    ## Ported from splatr1.pl
    sub findBlobBoxInSB {
        my ($self,$x,$y) = @_;
        die "Not in blob" if $self->getCharInSB($x,$y) eq " ";
        my ($minx,$maxx,$miny,$maxy) = ($x-1, $x+1, $y-1, $y+1);
        my $changed = 1;
        while ($changed) {
            if    ($self->notAllBlank($minx,$miny,$maxx,$miny)) { --$miny; }
            elsif ($self->notAllBlank($maxx,$miny,$maxx,$maxy)) { ++$maxx; }
            elsif ($self->notAllBlank($minx,$maxy,$maxx,$maxy)) { ++$maxy; }
            elsif ($self->notAllBlank($minx,$miny,$minx,$maxy)) { --$minx; }
            else { $changed = 0; }
        }
        return ($minx,$miny,$maxx-$minx,$maxy-$miny);
    }

    ## Ported from splatr1.pl
    # return undef if no blob in given direction, else blob bounding box
    sub scanForBlob {
        my ($self,$x,$y,$dx,$dy) = @_;
        die if $dx == 0 && $dy == 0;
        my ($wid,$hei) = $self->getSBSize();
        while (1) {
            return undef if $x < 0 || $y < 0 || $x >= $wid || $y >= $hei;
            if ($self->getCharInSB($x,$y) ne " ") {
                return $self->findBlobBoxInSB($x,$y);
            } else {
                $x += $dx;
                $y += $dy;
            }
        }
    }
    
    sub makeBlob {
        my ($self, $x, $y, $w, $h, $tag) = @_;
#        print STDERR "MDBl($self, $x, $y, $w, $h, $tag)\n";
        return SPLATtrNodeBlob->
            new($self->{s},
                sourceLine => $self->{sourceLine}, # would like to do better..
                sb => $self,                    
                x => $x,
                y => $y,
                width => $w,
                height => $h,
                tag => $tag,
            );
    }

    ## Ported from splatr1.pl
    sub findPatternsInSpatialBlock {
        my ($self,@args) = @_;
        $self->computeSBSize();
        return if $self->isEmptySB();

        my ($ptr,$ax,$ay) = (undef,-1,0);
        while (1) {
            my ($aw,$ah);
            ($ptr,$ax,$ay, $aw, $ah) = $self->nextPatternPointerInSB($ax,$ay);
            last unless defined($ptr);
#            generateOneLineComment " In $sk, found $ptr at ($ax,$ay,$aw,$ah)";
            my $ptrblob = $self->makeBlob($ax-$aw+1, $ay, $aw, $ah, $ptr);
            my ($x,$y,$w,$h);
            ($x,$y,$w,$h) = $self->scanForBlob($ax-length($ptr),$ay,-1,0);
            my $lhsblob;
            if (defined($x)) {
                die "NoDF1 y ($x,$y,$w,$h)" unless defined $y;
                $lhsblob = $self->makeBlob($x, $y, $w, $h, "LHS");
#                generateOneLineComment " In $sk, found LSB ($x,$y,$w,$h)";
            }
            ($x,$y,$w,$h) = $self->scanForBlob($ax+1,$ay,1,0);
            my $rhsblob;
            if (defined($x)) {
                die "NoDF2 y ($x,$y,$w,$h)" unless defined $y;
                $rhsblob = $self->makeBlob($x, $y, $w, $h, "RHS");
#                generateOneLineComment " In $sk, found RSB ($x,$y,$w,$h)";
            }
            my $pattern = SPLATtrNodePattern->new($self->{s},
                                                  LHS=>$lhsblob,
                                                  arrow=>$ptrblob,
                                                  RHS=>$rhsblob,
                                                  sourceLine=>$self->{sourceLine}, # better than nothing I guess
                );

            push @{$self->{patterns}}, $pattern;
#            generateOneLineComment "pat($pattern)";
        }
#        generateOneLineComment "<SB#$sk";
        if (0 == scalar @{$self->{patterns}}) {
            $self->{s}->printfError($self->{sourceLine},
                                    "No patterns found in non-empty spatial block");
        }
    }
}

1; # SPLATtrNodeUnitSpatialBlock.pm
