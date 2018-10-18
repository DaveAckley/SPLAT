package SPLATtrNodeSectionSplatRules {
    use parent "SPLATtrNodeSection";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            className => $params{className},
            ruleOrder => $params{ruleOrder},
            keysets => {},  # hash of KeyCode => KeySet
            );
        SPLATUrSelf::crash("Missing section level") 
            unless defined $self->{sectionLevel};
#        print STDERR  "SPLATtrNodeSectionSplatRules ".$self->{sectionLevel}."\n";
        SPLATUrSelf::crash("Missing ruleOrder") 
            unless defined $self->{ruleOrder};
        SPLATUrSelf::crash("Bad section level $params{sectionLevel}") 
            unless $self->{sectionLevel} >= 0;
        return bless($self,$class);
    }

    sub getKeySet {
        my ($self,$keyCode,$sourceLineIfNew) = @_;
#print STDERR "GETKEYSET($self,$keyCode)\n";
        $self->crash("Bad keycode '$keyCode'") 
            unless SPLATtrNodeKeySet::isKeyCode($keyCode);
        $self->crash("Need classname") 
            unless defined $self->{className};
        my $ks = $self->{keysets}->{$keyCode};
        if (!defined($ks)) {
            $self->crash("Need rulesetNumber") 
                unless defined $self->{rulesetNumber};
            $ks = SPLATtrNodeKeySet->new($self->{s}, 
                                         sourceLine => $sourceLineIfNew,
                                         inClassName => $self->{className},
                                         keyCode => $keyCode,
                                         rulesetNumber => $self->{rulesetNumber},
                );
            $self->{keysets}->{$keyCode} = $ks;
#print STDERR "ADDED($self=>{keysets}=>{$keyCode} = $ks;\n";
        }
        return $ks;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        my $sclass = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
        if (!defined($sclass)) {
            $self->{s}->printfError($self->{sourceLine},"Rules section outside of splat class");
            return undef;
        }
        $self->{className} = $sclass->{className};
        $self->{rulesetNumber} = scalar(@{$sclass->{ruleSets}});
        push @{$sclass->{ruleSets}}, $self;

        die "No SSI"
            unless defined($self->{sectionSubsectionIndex});

        return undef
            unless defined $self->SUPER::analysisPhase(@parents);

        for (my $u = 0; $u < scalar @{$self->{sectionBodyUnits}}; ++$u) {
            $self->{sectionBodyUnits}->[$u]->extractKeyCodes($self);
        }

        return $self;
    }

    sub codegenPhase {
        my ($self,@parents) = @_;
        $self->crash("No RuleSet number") unless defined $self->{rulesetNumber};

        ## First generate the key set classes
        for my $key (sort keys %{$self->{keysets}}) {
            $self->crash() unless SPLATtrNodeKeySet::isKeyCode($key);
            my $val = $self->{keysets}->{$key};
            return 0 unless $val->codegenKeySetForClass($self,@parents);
        }

        ## Then the ruleset class itself
        return 0 unless $self->codegenRuleSet(@parents);
        return 1;
    }

    sub getFullCName {
        ## begin dup from codegenKeySetForClass -- rs should set these all up?
        my ($self,@parents) = @_;
        my $out = $self->{s}->{outHandle};
        my $class = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
        my $className = $class->{className};
        $self->crash("Missing classname") unless defined($className);

        my $rulesetNumber = $self->{rulesetNumber};
        $self->crash("Missing rsn") unless defined($rulesetNumber);
        my $lexrsn = SPLATtr::toLex($rulesetNumber);
        ## end dup
        my $fullname = "SPLATRuleSet_$lexrsn$className";

        return $fullname;
    }

    sub codegenRuleSet {
        ## begin dup from codegenKeySetForClass -- rs should set these all up?
        my ($self,@parents) = @_;
#print STDERR "\n".$self->{s}->{inFileName}."-CODEGENRULESET($self,@parents)\n";
        my $out = $self->{s}->{outHandle};
        my $class = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
        my $className = $class->{className};
        $self->crash("Missing classname") unless defined($className);

        my $rulesetNumber = $self->{rulesetNumber};
        $self->crash("Missing rsn") unless defined($rulesetNumber);
        my $lexrsn = SPLATtr::toLex($rulesetNumber);
        ## end dup


        my $fullname = $self->getFullCName(@parents);

        print $out "\ntransient $fullname : SPLATRuleSet {\n";

        my $ksprefix = "SPLATKeyState_$lexrsn${className}_";
        my %ksmap;
        ## Phase 1 of 3: Generate data members
        foreach my $kc (sort keys %{$self->{keysets}}) {
            my $ks = $self->{keysets}->{$kc};
#print STDERR " $ks = $self=>{keysets}=>{$kc}\n";
            $self->crash() unless SPLATtrNodeKeySet::isKeyCode($kc);
            my $cKeyCodeName = SPLATtrNodeKeySet::cNameForKeyCode($kc);
            my $membername = "key_$cKeyCodeName";
            $ksmap{$kc} = $membername;
            print $out "  $ksprefix$cKeyCodeName $membername;\n";
#print STDERR "GEN  $ksprefix$cKeyCodeName $membername;\n";
        }

        ## Phase 2a of 3: Generate reset method
        print $out 
            "  virtual Void reset() {\n";
        print $out 
            "    super.reset();\n";
        foreach my $ks (sort keys %ksmap) {
            my $dm = $ksmap{$ks};
            print $out
                "    $dm.define('$ks');\n";
        }
        print $out 
            "  }\n";

        ## Phase 2b of 3: Generate beginSiteEval method
        print $out 
            "  virtual Void beginSiteEval() {\n";
        print $out 
            "    super.beginSiteEval();\n";
        foreach my $ks (sort keys %ksmap) {
            my $dm = $ksmap{$ks};
            print $out
                "    $dm.beginSiteEval();\n";
        }
        print $out 
            "  }\n";

        ## Phase 2 of 3: Generate accessor method
        print $out 
            "  virtual SPLATKeyState & getKeyState(ASCII key) {\n";
        print $out 
            "    which (key) {\n";
        foreach my $ks (sort keys %ksmap) {
            my $dm = $ksmap{$ks};
            print $out
                "    case '$ks': { return $dm; }\n";
        }
        print $out
            "    }\n";
        print $out
            "    return super.getKeyState(key);\n";
        print $out
            "  }\n";

        ## Phase 3 of 3: Generate rule evaluator method
        print $out
            "\n";
        print $out
            "  virtual Bool evaluateRules() {\n";
        print $out
            "    SPLATRuleDriver pd;\n";
        foreach my $u (@{$self->{sectionBodyUnits}}) {
            next unless ref $u eq "SPLATtrNodeUnitSpatialBlock";
            foreach my $p (@{$u->{patterns}}) {
                my $comment = $p->toMultilineString("    // ");
                print $out $comment;
                my $rulstr = $p->generateEvalString();
                print $out
                    "    if (pd.evaluateRule(self, \"$rulstr\"))\n";
                print $out
                    "      return true;\n";
            }
        }
        print $out
            "    return false;\n";
        print $out
            "  }\n";

        print $out
            "} // $fullname\n";

        return 1;
    }
}

1; # SPLATtrNodeSectionSplatRules.pm
