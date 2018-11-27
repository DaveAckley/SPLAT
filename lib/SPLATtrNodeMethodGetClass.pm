package SPLATtrNodeMethodGetClass {
    use parent "SPLATtrNode";
    our @ISA;

    my $selectorvar = SPLATSourceLine::getOoBVarName("selector");
    my $selfvar = SPLATSourceLine::getOoBVarName("self");
    my %dollarvarCodeGenInfo = (
        selector => $selectorvar,
        self => $selfvar,
        );

    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = bless($ISA[0]->new($splattr, %params),$class);
        %{$self} = (
            %{$self},
            className => $params{className},
            methodBody => undef,  # set by acceptBody
            );
        $self->crash("No className") unless defined $self->{className};
        return $self;
    }

    ## XX This needs to be generalized to include a dollavarinfo arg and moved higher
    sub mapSpecialVars {
        my ($self, $body) = @_;
        my $errors = 0;
        while ($body =~ /^(.*?)[\$]([a-z]+)([^a-z].*|)$/s) {
            my ($pre,$dolla,$post) = ($1,$2,$3);
            # Is this a special dollar variable
            my $translation = $dollarvarCodeGenInfo{$dolla};
            if (!defined($translation)) {
                $self->{s}->printfError($self->{sourceLine},"Undefined '\$%s' special variable in 'getColor' method starting here",
                                        $dolla);
                ++$errors;
                $translation = " $dolla";  # Change '$' to ' ' to avoid loop
            }
            $body = $pre.$translation.$post;
        }
        return undef if $errors > 0;
        return $body;
    }

    sub acceptBody {
        my ($self,$body) = @_;
        my $newbody = $self->mapSpecialVars($body);
        return undef unless defined $newbody;
        $self->{methodBody} = $newbody;
        return $self;
    }

    sub codegenMethod {
        my ($self) = @_;
        my $class = $self->{className};
        my $ret = "";
        $ret .= "    ARGB getColor(Unsigned $selectorvar) {\n";
        $ret .= "      ColorUtils cu;\n";
        $ret .= "      $class & $selfvar = self;\n";
        $ret .= $self->{methodBody};
        $ret .= "      return super.getColor($selectorvar);\n";
        $ret .= "    }\n";
        return $ret;
    }
}

1; # SPLATtrNodeMethodGetClass.pm
