package SPLATtrNodeSectionSplatClass {
    use parent "SPLATtrNodeSection";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            className => $params{className},
            classCategory => $params{classCategory},
            superClass => $params{superClass},
            ruleSets => [],
            dataMemberSentences => [],  # At present, only unanalyzed pure ulam sentences
            methods => [],              # methods and pure ulam
            );
        $self->{superClass} = "SPLATInstance" unless defined $self->{superClass};
        $self->crash("Missing section level") unless defined $self->{sectionLevel};
        $self->crash("Bad section level $params{sectionLevel}") 
            unless $self->{sectionLevel} >= 0;
        $self->crash("Missing class name") 
            unless defined($self->{className});
        $self->crash("Missing class category") 
            unless defined($self->{classCategory});
        return bless($self,$class);
    }

    sub codegenClassMetadata {
        my ($self) = @_;
        my $out = $self->{s}->{outHandle};

        my $openedComment = 0;
        # If there's a blurb we'll make a class comment for sure.
        my $blurb = $self->{sectionBlurb};
        $blurb = "" unless defined $blurb;

        my $metadata = "";
        my $localdefs = "";

        # We'll check if there's an initial sentential group in the
        # sectionBodyUnits.  If so, we'll scan it for lines beginning
        # with '\' and assume they are metadata.  And I guess, for
        # now, we'll die on anything else.

        return 1                # No units is OK by us
            if $blurb eq "" && scalar(@{$self->{sectionBodyUnits}}) == 0;

        my $firstUnit = $self->{sectionBodyUnits}->[0];

        return 1                # Non-sentential is OK by us
            if $blurb eq "" && ref($firstUnit) ne "SPLATtrNodeSententialGroup";

        my $errors = 0;
        foreach my $sentence (@{$firstUnit->{sentences}}) {
            my $text = $sentence->getText();

            if ($text =~ /^[\\]/) {
                $metadata .= "  $text\n";
                next;
            }
            if ($text =~ /^(local .*)$/) {
                $localdefs .= "$1\n";
            } else {
                $self->{s}->printfError($sentence->{sourceLine},"Sentence does not look like metadata or local def");
                ++$errors;
            }
            next;
        }

        print $out $localdefs; # if any

        if ($blurb ne "") {
            print $out "/** $blurb\n";
            $openedComment = 1;
        }

        if ($metadata ne "" && !$openedComment) {
            print $out "/** \n";
            $openedComment = 1;
        }
        
        print $out $metadata; # if any

        if ($openedComment) {
            print $out " */\n";
        }


        return 1;
    }

    sub codegenPhase {
        my ($self,@parents) = @_;

        ### PART II: Start the class itself
        my $out = $self->{s}->{outHandle};
        my $className = $self->{className};
        $self->crash("Missing classname") unless defined($className);

        print $out 
            "\n";
        return 0 unless $self->codegenClassMetadata();

        my $cat = $self->{classCategory};
        my $super = $self->{superClass};
        print $out 
            "$cat $className : $super {\n";

        ### PART III: Custom data members
        print $out
            "  // Data members\n";
        foreach my $sentence (@{$self->{dataMemberSentences}}) {
            my $ulamText = $sentence->getUlamText();
            $self->crash("Not ulam sentence") unless defined $ulamText;
            print $out
                "  $ulamText\n";
        }

        ### PART IV: Generate the rule sets evaluator
        print $out
            "  virtual Bool evaluateRuleSets() {\n";

        # Do pre rules
        for (my $u = 0; $u < scalar @{$self->{ruleSets}}; ++$u) {
            my $rs = $self->{ruleSets}->[$u];
            next unless $rs->{ruleOrder} eq "pre";
            my $rscn = $rs->getFullCName($self,@parents);
            print $out
                "    {\n";
            print $out
                "      $rscn rs;\n";
            print $out
                "      if (rs.evaluateRules()) return true;\n";
            print $out
                "    }\n";
        }

        # Do bespoke super class
#      print STDERR " Do bespoke super class(on $super)\n";
        if ($super ne "SPLATInstance") {
            print $out
                "    if (super.evaluateRuleSets()) return true; // Maybe super's got something\n";
        }

        # Do post rules
        for (my $u = 0; $u < scalar @{$self->{ruleSets}}; ++$u) {
            my $rs = $self->{ruleSets}->[$u];
            next unless $rs->{ruleOrder} eq "post";

            my $rscn = $rs->getFullCName($self,@parents);
            print $out
                "    {\n";
            print $out
                "      $rscn rs;\n";
            print $out
                "      if (rs.evaluateRules()) return true;\n";
            print $out
                "    }\n";
        }

        print $out
            "    return false;   // We got nothing\n";
        print $out
            "  }\n";

        ### PART V: Generate bespoke methods
        for (my $u = 0; $u < scalar @{$self->{methods}}; ++$u) {
            my $unit = $self->{methods}->[$u];
            if (ref $unit eq "SPLATtrNodeSentence") {
                my $text = $unit->getUlamText();
                print $out $text;
                next;
            }
            if (ref $unit eq "SPLATtrNodeMethodGetClass") {
                my $body = $unit->codegenMethod();
                $self->crash() unless defined $body;
                print $out $body;
                next;
            }
            $self->crash("Unrecognized method unit $u: '$unit'");
        }

        ### PART VI: End the class
        print $out
            "\n} // $cat $className\n";

        ### PART I: Do the rulesets
        for (my $u = 0; $u < scalar @{$self->{ruleSets}}; ++$u) {
            my $rs = $self->{ruleSets}->[$u];
            $self->crash("Not ruleset") unless (ref $rs eq "SPLATtrNodeSectionSplatRules");
            return 0 unless $rs->codegenPhase($self,@parents);
        }

        return 1; 
    }

}

1; # SPLATtrNodeSectionSplatClass.pm
