# SPLATv1 pseudogrammar
#  <PROGRAM> := <SECTION_BODY> + <EOF>
#  <SECTION> := <SECTION_HEADER> + <SECTION_BODY>
#  <SECTION_BODY> := <UNIT>* + <SECTION>*
#  <SECTION_HEADER> := <SECTION_LEVEL> + <SECTION_DESCRIPTOR>
#  <SECTION_DESCRIPTOR> := <SPLAT_SECTION_DESCRIPTOR> | <ULAM_SECTION_DESCRIPTOR>
#  <SPLAT_SECTION_DESCRIPTOR> := 'splat' + ( 'quark' | 'element' ) + <ULAM_CLASS_NAME>
#  <ULAM_SECTION_DESCRIPTOR> := <FAIL_UNIMPLEMENTED>
#  <UNIT> := <SENTENTIAL_GROUP> | <SPATIAL_BLOCK>
#  <SENTENTIAL_GROUP> := <SENTENCE> | <SENTENCE> + <SENTENTIAL_GROUP>
#  <SENTENCE> := <NON_CONTINUATION_LINE> + <CONTINUATION_LINE>*
#  <NON_CONTINUATION_LINE> := /^[^\s+].*$/
#  <CONTINUATION_LINE> := /^[+].*$/
#  <SPATIAL_BLOCK> := <SPATIAL_LINE> | <SPATIAL_LINE> <SPATIAL_BLOCK>
#  <SPATIAL_LINE> := /^\s+.*$/

# SPLAT parse tree node
package SPLATtrNode {
    use parent "SPLATUrSelf";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            sourceLine => $params{sourceLine},
            );
        return bless $self, $class;
    }

    sub isANode {
        my ($self,$other) = @_;
        return SPLATtr::isSubtypeOf($other,"SPLATtrNode");
    }

    sub decircle {
        my ($self, $seenref) = @_;
        return if defined($seenref->{$self});
        $seenref->{$self} = 1;
        foreach my $key (keys %{$self}) {
            my $val = $self->{$key};
            my $type = ref $val;
            next unless defined $type;
            if ($type eq "ARRAY") {
                foreach my $i (@{$val}) {
                    if ($self->isANode($i)) {
                        $i->decircle($seenref);
                    }
                }
            } elsif ($type eq "HASH") {
                foreach my $k (keys %{$val}) {
                    my $v = $val->{$k};
                    if ($self->isANode($v)) {
                        $v->decircle($seenref);
                    }
                }
            }
            next unless SPLATtr::isSubtypeOf($val,"SPLATtrNode");
            $val->decircle($seenref);
            delete $self->{$key};
        }
        
    }

    sub getDefined {
        my ($val) = @_;
        return $val if defined $val;
        die "Undefined value illegal";
    }
    sub dump {
        my ($self,$maxdepth,$handle) = @_;
        $maxdepth = 2 unless defined $maxdepth;
        $self->{s}->dumpThis($self,0,$maxdepth);
    }

    sub getClassFromParents {
        my ($self,$classname,@parents) = @_;
        foreach my $class (@parents) {
            return $class if ref $class eq $classname;
        }
        return undef;
    }

    # This needs to be overridden
    sub analysisPhase {
        my ($self,@parents) = @_;
        die "No analysisPhase() method found for class ".(ref $self);
        return $self; # Not reached, but to show the pattern
    }

    # This needs to be overridden
    sub codegenPhase {
        my ($self,@parents) = @_;
        die "No codegenPhase() method found for class ".(ref $self);
        return 1; # Not reached, but to show the return bool pattern
    }
}

1; #SPLATtrNode.pm
