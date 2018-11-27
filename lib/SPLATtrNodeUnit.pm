package SPLATtrNodeUnit {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            sectionUnitIndex => undef,
            );
        return bless($self,$class);
    }

    sub newIfParse {
        my ($class, $s) = @_;
        my $self = $class->new($s);
    
        # Try for a sentential group.  They're nice
        my $unit = SPLATtrNodeSententialGroup->newIfParse($s);
        return $unit if defined $unit;

        # Well, try for a spatial block then.  We like them too.
        $unit =  SPLATtrNodeUnitSpatialBlock->newIfParse($s);
        return $unit if defined $unit;

        # Poop.
        return undef;
    }
}

1; #SPLATtrNodeUnit.pm
