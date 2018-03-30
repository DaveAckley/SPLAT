package SPLATtrNodeSectionSplatProgram {
    use parent "SPLATtrNodeSection";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            );
        $self->crash("Missing section level") unless defined $self->{sectionLevel};
        $self->crash("Bad section level $params{sectionLevel}") 
            unless $self->{sectionLevel} == 0;
        return bless($self,$class);
    }
}

1; # SPLATtrNodeSectionSplatProgram.pm
