package SPLATtrNodeSententialGroup {
    use parent "SPLATtrNodeUnit";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            sentences => [],
            );
        return bless($self,$class);
    }

    sub newIfParse {
        my ($class, $s) = @_;
        my $self = $class->new($s);
        my $re = qr/^[^=\1]/;  # We want sentences that aren't section headers or EOF
        my $sentence = SPLATtrNodeSentence->newIfParse($s,$re);
        return undef unless defined $sentence;  # Need at least one sentence to be a group
        $self->{sourceLine} = $sentence->{sourceLine}; # First line of first sentence represents the group
        while (1) {
            push @{$self->{sentences}}, $sentence;
            $sentence = SPLATtrNodeSentence->newIfParse($s,$re);
            last unless defined $sentence;
        }
        return $self;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        for (my $s = 0; $s < scalar @{$self->{sentences}}; ++$s) {
            my $a = $self->{sentences}->[$s]->analysisPhase($self,@parents);
            return undef unless defined $a;
            $self->{sentences}->[$s] = $a;
        }

        return $self;
    }

    sub extractKeyCodes {
        my ($self,$ruleset) = @_;
        for (my $s = 0; $s < scalar @{$self->{sentences}}; ++$s) {
            $self->{sentences}->[$s]->extractKeyCodes($ruleset);
        }
    }

}

1; #SPLATtrNodeSententialGroup.pm
