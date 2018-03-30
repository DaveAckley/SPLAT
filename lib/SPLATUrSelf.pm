### Our universal base class
package SPLATUrSelf {
    sub new {
        my ($class, $splattr, %params) = @_;
        # We allow undef $splattr to break the loop for SPLATtr
        # itself, so other immediate subclasses (e.g., SPLATtrNode)
        # should check that themselves.
        return bless {
            s => $splattr,
        }, $class;
    }
    sub dump {
        my ($self,$depth,$handle) = @_;
        $self->{s}->dumpThis($self,0,$depth);
    }
    sub assertClass {
        my ($self,$object,$class) = @_;
        $self->crash("Missing class in assertClass") unless defined $class;
        $self->crash("Expected $class but got undef") unless defined $object;
        my $type = ref($object);
        return if $type eq $class;
        $self->crash("Expected type $class but got '$object'");
    }

    # try to make crash callable any old way:
    # by namespace 'SPLATUrSelf::crash("message")',
    # by class     'SPLATUrSelf->crash("message")', or
    # by object    '$self->crash("message"), 
    # with $self inheriting from SPLATUrSelf.
    sub crash {
        my $msg = shift;
        $msg = shift
            if ref $msg || $msg eq "SPLATUrSelf";

        $msg = "Unspecified error" unless defined $msg;
        die "INTERNAL ERROR, EXITING: $msg\n";
    }

}

1; #SPLATUrSelf.pm
