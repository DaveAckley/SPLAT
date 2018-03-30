package SPLATtrNodeSectionSplatDataMembers {
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
            $self->{s}->printfError($self->{sourceLine},"Data members section outside of splat class");
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
                    $self->{s}->printfError($u->{sourceLine},"Spatial block illegal in Data members section");
                    ++$errors;
                    next;
                }
            } elsif (ref $u eq "SPLATtrNodeSententialGroup") {
                for my $sentence (@{$u->{sentences}}) {
                    my $ulamText = $sentence->getUlamText();
                    if (!defined($ulamText)) {  # Only accept 'u'lam sentences for now.
                        ++$errors;
                        $self->{s}->printfError($sentence->{sourceLine},
                                                "Unrecognized data section sentence");
                        next;
                    }
                    push @{$sclass->{dataMemberSentences}}, $sentence;
                }
            }
        }
        if ($errors > 0) {
            return undef;
        }

        return $self;
    }
}

1; # SPLATtrNodeSectionSplatDataMembers.pm
