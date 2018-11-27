package SPLATSourceLine {
    # Create a SPLATSourceLine, after checking the supplied line for sanity in various ways
    sub new {
        my ($class, $splattr, $filename, $line, $lineno) = @_;
        my $self = { };
        bless $self, $class;
        $self->crash unless defined $lineno;
        $self->{fileName} = $filename;
        $self->{lineNumber} = $lineno;
#print "FOO!    $self,    $self->{lineNumber} = $lineno;\n";

        if ($line !~ /.*\n$/) {
            $splattr->printfError($self, "Missing or invalid line terminator");
        }

        chomp($line);

        # Eat all non-ASCII
        while ($line =~ s/^(.*?)([^[:ascii:]])(.*)$/$1$3/) {
            my $chr = $2;
            $splattr->printfError($self,"Non-ASCII byte '\\\%03o'",ord($chr));
        }

        # Eat everything but ASCII graphical chars and the plain space ' ' (no tab etc)
        while ($line =~ s/^(.*?)([^[:graph:] ])(.*)$/$1$3/) {
            my $chr = $2;
            if ($chr =~ /[[:cntrl:]]/) {
                $splattr->printfError($self,"Illegal byte '^%c'",ord($chr) + ord('A') - 1);
            } else {
                $splattr->printfError($self,"Illegal byte '\\\%03o'",ord($chr));
            }
        }

        # Eat the magic splat codes (yes, even in strings and comments etc. heck with you for asking.)
        my $magicOoBVar = getOoBVarPrefix();
        my $magicOoBType = getOoBTypePrefix();
        while ($line =~ /^(.*?)($magicOoBVar|$magicOoBType)(.*)$/) {
            $line = "$1$3";
            $splattr->printfError($self,"Discarded reserved internal SPLAT sequence.  Really?");
        }
        $self->{line} = $line;

        return $self;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        return $self; # We Are Good
    }


    sub getLocation {
        my $self = shift;
#print "BAR!      $self,  $self->{lineNumber}\n";
        return $self->{fileName}.":".$self->{lineNumber};
    }

    sub getText {
        my $self = shift;
        return $self->{line};
    }

    sub getLabeledLine {
        my $self = shift;
        return $self->getLocation().":".$self->getText();
    }

    #### STATIC METHODS
    sub getOoBVarPrefix {
        return "splATTROoB__";
    }
    sub getOoBTypePrefix {
        return "SPLattrOoB__";
    }
    sub getOoBVarName {
        my $name = shift;
        return getOoBVarPrefix()."$name";
    }
    sub getOoBTypeName {
        my $name = shift;
        return getOoBTypePrefix()."$name";
    }

}

1; #SPLATSourceLine.pm
