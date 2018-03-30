package SPLATtrNodeSectionSplatMethods {
    use parent "SPLATtrNodeSection";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            className => $params{className},
            );
        $self->crash("Missing section level") unless defined $self->{sectionLevel};
        $self->crash("Bad section level $params{sectionLevel}") 
            unless $self->{sectionLevel} >= 0;
        return bless($self,$class);
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        my $sclass = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
        if (!defined($sclass)) {
            $self->{s}->printfError($self->{sourceLine},"Methods section outside of splat class");
            return undef;
        }
        $self->{className} = $sclass->{className};

        die "No SSI"
            unless defined($self->{sectionSubsectionIndex});

        return undef
            unless defined $self->SUPER::analysisPhase(@parents);

        my $errors = 0;
        foreach my $u (@{$self->{sectionBodyUnits}}) {
            if (ref $u eq "SPLATtrNodeUnitSpatialBlock") {
                if (scalar(@{$u->{patterns}}) > 0) {
                    $self->{s}->printfError($u->{sourceLine},"Spatial block illegal in Methods section");
                    ++$errors;
                    next;
                }
            } elsif (ref $u eq "SPLATtrNodeSententialGroup") {
                for my $sentence (@{$u->{sentences}}) {
                    if (defined($sentence->getUlamText())) {  # Just accept 'u'lam sentences and 'special methods' for now
                        push @{$sclass->{methods}}, $sentence;
                        next;
                    }
                    my $text = $sentence->getText();
                    chomp $text;
                    if ($text =~ /^(getColor)\s*([\{].*[\}])$/s) {
                        my $curlybody = $2;
                        my $gcmeth = SPLATtrNodeMethodGetClass->new($self->{s},
                                                                    sourceLine => $sentence->{sourceLine},
                                                                    className => $self->{className},
                            );
                        if (defined($gcmeth->acceptBody($curlybody))) {
                            push @{$sclass->{methods}}, $gcmeth;
                        } else {
                            ++$errors; # (but message already issued)
                        }
                        next;
                    }
                    ++$errors;
                    $self->{s}->printfError($sentence->{sourceLine},
                                            "Unrecognized sentence in methods");
                }
            }
        }
        if ($errors > 0) {
            return undef;
        }

        return $self;
    }
}

1; # SPLATtrNodeSectionSplatMethods.pm
