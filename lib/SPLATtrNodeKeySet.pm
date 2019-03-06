package SPLATtrNodeKeySet {
    use parent "SPLATtrNode";
    our @ISA;
    # Default translations for dollar vars
    my $rsvar = SPLATSourceLine::getOoBVarName("rs");
    my $selfvar = SPLATSourceLine::getOoBVarName("self");
    my $snvar = SPLATSourceLine::getOoBVarName("cursn");
    my $atomvar = SPLATSourceLine::getOoBVarName("curatom");
    my %dollarvarCodeGenInfo = (
        nsites => "getNumberSites()",
        nvotes => "getNumberVotes()",
        cursn => "splATTROoB__cursn",
        winsn => "getWinnerSN()",
        picksn => "getPickSN()",
        curatom => "splATTROoB__curatom",
        pickatom => "getPickAtom()",
        winatom => "getWinnerAtom()",
        keystate => "getKeyState()",
        ruleset => "splATTROoB__rs",
        self => $selfvar,
        );
    # Which dollar vars are valid in which override codes?
    my %dollarvarValidOverrides = (
        cursn => { given => 1, vote => 1, change => 1 },
        curatom => { given => 1, vote => 1, change => 1 },
        picksn => { ALL => 1, check => 1, change => 1 },
        pickatom => { ALL => 1, check => 1, change => 1 },
        winsn => { ALL => 1, check => 1, change => 1 },
        winatom => { ALL => 1, check => 1, change => 1 },
        nsites => { ALL => 1, check => 1, change => 1 },
        nvotes => { ALL => 1, check => 1, change => 1 },
        keystate => { ALL => 1 },
        ruleset => { ALL => 1 },
        key => { ALL => 1 },
        self => { SPECIAL => 1 },
        );
    my %overrideCodegenInfo = ( 
        given => {
            ReturnType=>"Bool", 
            NotISAValue=>"false", 
            MethodSig=>"given(SPLATRuleSet & $rsvar, SN $snvar, Atom & $atomvar)", 
        },
        vote => {
            ReturnType=>"Votes", 
            NotISAValue=>"0u", 
            MethodSig=>"vote(SPLATRuleSet & $rsvar, SN $snvar, Atom & $atomvar)", 
        },
        check => {
            ReturnType=>"Bool", 
            NotISAValue=>"false", 
            MethodSig=>"check(SPLATRuleSet & $rsvar)", 
        },
        change => {
            ReturnType=>"Void", 
            NotISAValue=>"", 
            MethodSig=>"change(SPLATRuleSet & $rsvar, SN $snvar, Atom & $atomvar)", 
        },
        );
    my %namesForSpecialKeyCodes = (
        "_" => "Underline",
        "@" => "At",
#        "=" => "Equals",
        "." => "Dot",
        "?" => "Ask",
        );
    my %baseClassForSpecialKeyCodes = (
        "_" => "SPLATKeyStateEmpty",
        "@" => "SPLATKeyStateSelf",
#        "=" => "SPLATKeyStateSelfType",
        "." => "SPLATKeyStateAny",
        "?" => "SPLATKeyStateOccupied",
        );
    
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            inClassName => $params{inClassName},
            keyCode => $params{keyCode},
            rulesetNumber => $params{rulesetNumber},
            overrides => {},  # type -> [$delim, optisa, delim-specific-body, source-line]
            );
        $self->crash("Missing class name") unless defined $self->{inClassName};
        $self->crash("Missing key code") unless defined $self->{keyCode};
        $self->crash("Bad key code '%s'",$self->{keyCode}) 
            unless isKeyCode($self->{keyCode});
        return bless($self,$class);
    }

    sub isAllDefaults {
        my $self = shift;
        return scalar(keys %{$self->{overrides}}) == 0;
    }

    sub isKeyCode {
        my $code = shift;
        return 0 unless defined $code;
        return $code =~ /^[_@.*?a-zA-Z]$/;
    }
    
    sub cNameForKeyCode {
        my $code = shift;
        return $namesForSpecialKeyCodes{$code} if defined $namesForSpecialKeyCodes{$code};
        return $code if $code =~ /^[a-zA-Z]$/;
        return undef;
    }

    sub cBaseClassForKeyCode {
        my $code = shift;
        return $baseClassForSpecialKeyCodes{$code} if defined $baseClassForSpecialKeyCodes{$code};
        return "SPLATKeyState" if $code =~ /^[a-zA-Z]$/;
        return undef;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        if (scalar(@parents)==0 || ref $parents[0] ne "SPLATtrNodeSectionSplatClass") {
            $self->{s}->printfError($self->{sourceLine},"Rules section outside of splat class");
            return undef;
        }
        die "No SSI"
            unless !defined($self->{sectionSubsectionIndex});

        return $self->SUPER::analysisPhase(@parents);
    }

    sub codegenKeySetForClass {
        my ($self,@parents) = @_;
        my $out = $self->{s}->{outHandle};
        my $class = $self->getClassFromParents("SPLATtrNodeSectionSplatClass",@parents);
        my $className = $class->{className};
        $self->crash("Missing classname") unless defined($className);

        my $rulesetNumber = $self->{rulesetNumber};
        $self->crash("Missing rsn") unless defined($rulesetNumber);
        my $lexrsn = SPLATtr::toLex($rulesetNumber);

        my $cKeyCodeName = cNameForKeyCode($self->{keyCode});
        $self->crash("Bad keycode name: '$self->{keyCode}'") 
            unless defined($cKeyCodeName);

        my $fullname = "SPLATKeyState_$lexrsn${className}_$cKeyCodeName";

        my $cBaseClass = cBaseClassForKeyCode($self->{keyCode});
        $self->crash("Bad keycode name") unless defined($cBaseClass);


        my $voteOverride = $self->{overrides}->{vote};
        if (defined($voteOverride) && defined($voteOverride->[4]) && $voteOverride->[4]) {
            $cBaseClass .= 'Max';
#            print "CLLLANNDNDIOOOOIL($voteOverride,$cBaseClass)\n"
        }
#        print "FNNFFNOIIIIL() ".::Dumper($self->{overrides})."\n";

        print $out "\ntransient $fullname : $cBaseClass {\n";

        foreach my $override (sort keys %{$self->{overrides}}) {
            my $overridebody = $self->{overrides}->{$override};
#            print "LDKLSDLKDSKLDS ".::Dumper($overridebody)."\n";
            $self->codegenOverrideForKeySet($out,$override,$overridebody);
        }
        print $out "} // transient $fullname\n";
        return 1;
    }

    sub codegenMapDollaVars {
        my ($self,$body,$override,$overridesourceline,$selfVarOrUndef) = @_;
        while ($body =~ /^(.*?)[\$]((\d+)|[._@?]|[a-zA-Z]+)([^a-zA-Z].*|)$/s) {
            my ($pre,$dolla,$scratch,$post) = ($1,$2,$3,$4);
            # Is this a scratch variable reference?
            if (defined($scratch)) {
                if ($scratch > 9) {
                    $self->{s}->printfError($overridesourceline,"'\$%s' illegal scratch var in '%s %s' code starting here",
                                            $scratch,
                                            $override,
                                            $self->{keyCode});
                    return undef;
                }
                my $rsvar = $dollarvarCodeGenInfo{'ruleset'};
                my $translation = "($rsvar.getScratchVar($scratch))";
                $body = $pre.$translation.$post;
                next;
            }
            # Is this a special dollar variable
            my $translation = $dollarvarCodeGenInfo{$dolla};
            if (defined($translation)) { # Is this a special dolla var?
                # Yes, is it legal in this override?
                my $otab = $dollarvarValidOverrides{$dolla};
                $self->crash("Missing val tab for '$dolla'") unless defined $otab;
                if (defined($otab->{SPECIAL})) {
                    if ($dolla eq "self") {
                        if (defined($selfVarOrUndef)) {
                            $body = $pre.$selfVarOrUndef.$post;
                        } else {
                            $self->{s}->printfError($overridesourceline,"'\$%s' illegal in non-isa '%s %s' code starting here",
                                                    $dolla,
                                                    $override,
                                                    $self->{keyCode});
                            return undef;
                        }
                    } else {
                        $self->crash("Unimplemented special var '$dolla'");
                    }
                } elsif (defined($otab->{ALL}) || defined($otab->{$override})) {
                    # OK, all good (not bothering to warn about posssible instability)
                    $body = $pre.$translation.$post;
                } else {
                    $self->{s}->printfError($overridesourceline,"'\$%s' illegal in '%s %s' code starting here",
                                            $dolla,
                                            $override,
                                            $self->{keyCode});
                    return undef;
                }
            } elsif ($dolla =~ /^[a-zA-Z._@?]$/) { # Is this a cross keycode reference?
                my $kcrefcode = "($rsvar.getKeyState('$dolla'))";  # Yeah, go hunt down its key state
                $body = $pre.$kcrefcode.$post;
            } else {
                $self->{s}->printfError($overridesourceline,"Undefined '\$%s' special variable in '%s %s' code starting here",
                                        $dolla,
                                        $override,
                                        $self->{keyCode});
                return undef;
            }
        }
        return $body;
    }

    sub makeStringForKeyExpr1 {
        my ($self, $tree, $ir, $lr) = @_;
        my $idx = $$ir++;
        my $p = 4*$idx;
        push @{$lr}, ("\\000")x4; # Reserve our slot

        if (0) { }
        elsif ($tree->[0] eq "key") {
            $lr->[$p+2] = $tree->[1];
        } 

        elsif ($tree->[0] eq "unop") {
            $lr->[$p+0] = $self->makeStringForKeyExpr1($tree->[2],$ir,$lr);
            $lr->[$p+3] = $tree->[1];
        } 

        elsif ($tree->[0] =~ /^(expr|factor|term)$/) {
            $lr->[$p+0] = $self->makeStringForKeyExpr1($tree->[2],$ir,$lr);
            $lr->[$p+1] = $self->makeStringForKeyExpr1($tree->[3],$ir,$lr);
            $lr->[$p+3] = $tree->[1];
        }

        else {
            $self->crash("makeStringForKeyExpr1 unrecognized '$tree->[0]'");
        }

        return sprintf("\\%03o",$idx);
    }

    sub makeStringForKeyExpr {
        my ($self, $keyexprtree) = @_;
        my $index = 0;
        my @l = "";
        $self->makeStringForKeyExpr1($keyexprtree,\$index,\@l);
        return '"'.join("",@l).'"';
    }

    # sub codegenKeyExprOverrideForKeySet {
    #     my ($self, $out, $optisa, $keyexprtree) = @_;
    #     print STDERR "codegenKeyExprOverrideForKeySet:";
    #     SPLATtrNodeSentence::printKeyExpr(STDERR,$keyexprtree);
    #     $self->crash("codegenKeyExprOverrideForKeySet(..,".($optisa ? $optisa : "NO OPT").",$keyexprtree)");
    # }

    sub makeOverrideWrapperForISA {
        my ($self, $type, $override, $oi) = @_;
        $self->crash("ISA illegal for override $override") if $override eq "check";
        # All other overrides have $curatom.
        my $selfvar = SPLATSourceLine::getOoBVarName("self");  
        my $notisaval = $oi->{NotISAValue};
        my ($pre, $defaultbody, $post) = ("","","");

        # for all overrides (but not used on 'change isa [no body]')
        $pre .= "  if (!(\$curatom is $type)) return $notisaval;\n";
        $pre .= "  $type & $selfvar = ($type &) \$curatom;\n";

        if ($override eq "given") { 
            $defaultbody .= "true";
        } elsif ($override eq "vote") {
            $defaultbody .= "1u";
        } elsif ($override eq "change") {
            $defaultbody .=  " ew[\$cursn] = ${type}.instanceof;";
        } else {
            $self->crash("wtf($override)");
        }

        return ($pre,$defaultbody,$post);
    }
#             my $type = $optisa;
#             if ($override eq "change" && $delim eq ":") {  # for 'change x isa Foo',
#                 $delim = "{";
#                 $body = " ew[\$cursn] = ${type}.instanceof; }";
#             } elsif ($override eq "given" && $delim eq ":") {  # for 'given x isa Foo',
#                 $body = "true";  # append a 'true' for them
#             } elsif ($override eq "vote" && $delim eq ":") {  # for 'vote x isa Foo',
#                 $body = "ew[\$cursn] is $type";  
#             } 
#             $selfvar = SPLATSourceLine::getOoBVarName("self");  # Having isa means you get self
#             my $tmpref = SPLATSourceLine::getOoBVarName("tmpref");
#             my $notisaval = $oi->{NotISAValue};
#             print $out <<EOC
#                 Atom & $tmpref = $curatomvar;
#     if (!($tmpref is $type)) return $notisaval;
#     $type & $selfvar = ($type &) $tmpref;
# EOC

    sub codegenOverrideForKeySet {
        my ($self,$out,$override,$ksr) = @_;
        my ($delim, $optisa, $overridebody, $overridesourceline, $voteMax) = @{$ksr};
        $voteMax ||= 0;
        my $origbody = $overridebody;
        my $prefix = "  // ";
        my $echoBack;
        if (ref $overridebody eq "ARRAY") {
            my $expr;
            open my ($str_fh), '>', \$expr or die "$!";
            SPLATtrNodeSentence::printKeyExpr($str_fh, $overridebody);
            close $str_fh or die "$!";
            $echoBack =
                SPLATtr::prefixIndent($prefix,"$override ".($voteMax?"max ":"").$self->{keyCode}." ".
                                      ($optisa?"isa $optisa ":" ").
                                      "= $expr");
        } else {
            $echoBack =
                SPLATtr::prefixIndent($prefix,"$override ".($voteMax?"max ":"").$self->{keyCode}." ".
                                      ($optisa?"isa $optisa ":" ").
                                      ($overridebody eq ""?"":"$delim $overridebody"));
        }
        ###
        ## CODEGEN RULE COMMENT
        print $out $echoBack;
        my $oi = $overrideCodegenInfo{$override};
        $self->crash("No codegen info for override '$override'")
            unless defined $oi;

        ###
        ## CODEGEN METHOD SIGNATURE FOR OVERRIDE
        print $out "  ".$oi->{ReturnType}." ".$oi->{MethodSig}." {\n";

        defined($delim)
            or $self->crash("Missing override delim '$overridebody'");
        my $selfvar = undef; # Default to can't use
        my $rsvar = SPLATSourceLine::getOoBVarName("rs");  # the ruleset
        my $cursnvar = SPLATSourceLine::getOoBVarName("cursn");  # cursn is an argument now
        my $curatomvar = SPLATSourceLine::getOoBVarName("curatom");  # curatom is an argument now too

        ###
        ## ANALYZE CASES AND DERIVE $body FOR LATER DOLLA-EXPANSION
        my ($pre,$defaultbody,$post) = ("","","");
        my $hasisa = 0;

        ##
        # CODEGEN OPTISA PRESENT
        if (defined($optisa)) {
            $hasisa = 1;
            $selfvar = SPLATSourceLine::getOoBVarName("self"); # Now can use
            ($pre, $defaultbody, $post) = $self->makeOverrideWrapperForISA($optisa,$override,$oi);
        } else { $optisa = ""; }

        my $body = "";

        if (0) { } # to make all cases below 'elsif's

        #CGKS given isa Foo [no body]
        elsif ($override eq "given" && $hasisa && $overridebody eq "") {
            $body .= "$pre return ($defaultbody); $post\n";
        }

        #CGKS given [no isa] [no body]
        elsif ($override eq "given" && !$hasisa && $overridebody eq "") {
            $body .= "  return (true); \n";
        }

        #CGKS given [no isa] : body
        elsif ($override eq "given" && !$hasisa && $delim eq ":" && $overridebody ne "") {
            $body .= "  return (\n$overridebody\n);";
        }

        #CGKS given [no isa] { curlybody }
        elsif ($override eq "given" && !$hasisa && $delim eq "{") {
            $body .= "{\n$overridebody\n}";
            $body .= "\nreturn true;";
        }

        #CGKS (given|vote|change) [no isa] = keyexpr
        elsif ($override =~ /^(given|vote|change)$/ && !$hasisa && $delim eq "=" && $overridebody ne "") {
            my $string = $self->makeStringForKeyExpr($overridebody);
            my $op = ucfirst($override);
            $body .= "  return interpret${op}Expr($rsvar,$cursnvar,$curatomvar,$string,0u);\n";
        }

        #CGKS given isa = keyexpr
        elsif ($override eq "given" && !$hasisa && $delim eq "=" && $overridebody ne "") {
            $self->crash("IMPLEMENT ME");
            my $string = $self->makeStringForKeyExpr($overridebody);
            $body .= "  String givenExpr = $string;\n";
            $body .= "  return interpretGivenExpr(givenExpr);\n";
        }

        #CGKS given isa : colonbody
        elsif ($override eq "given" && $hasisa && $delim eq ":" && $overridebody ne "") {
            $body .= $pre;
            $body .= "  return (\n$overridebody\n);";
        }

        #CGKS given isa { curlybody }
        elsif ($override eq "given" && $hasisa && $delim eq "{") {
            $body .= $pre;
            $body .= "{\n$overridebody\n}";
            $body .= "\nreturn $defaultbody;\n";
        }

        #CGKS vote [no isa] : body
        elsif ($override eq "vote" && !$hasisa && $delim eq ":" && $overridebody ne "") {
            $body .= "  return (\n$overridebody\n) ? 1u : 0u;";
        }

        #CGKS vote [no isa] { curlybody }
        elsif ($override eq "vote" && !$hasisa && $delim eq "{") {
            $body .= "{\n$overridebody\n}";
            $body .= "\nreturn 1u;";
        }

        #CGKS vote isa { curlybody }
        elsif ($override eq "vote" && $hasisa && $delim eq "{") {
            $body .= $pre;
            $body .= "{\n$overridebody\n}";
            $body .= "\nreturn $defaultbody;\n";
        }

        #CGKS vote isa : [no body]
        elsif ($override eq "vote" && $hasisa && $delim eq ":" && $overridebody eq "") {
            $body .= $pre;
            $body .= "return 1u;";
        }

        #CGKS vote isa : colonbody 
        elsif ($override eq "vote" && $hasisa && $delim eq ":" && $overridebody ne "") {
            $body .= $pre;
            $body .= "{return (\n$overridebody\n) ? 1u : 0u;}";
            $body .= $post;
        }

        #CGKS check { curlybody }
        elsif ($override eq "check" && !$hasisa && $delim eq "{") {
            $body .= "{\n$overridebody\n}";
            $body .= "\nreturn super.check($rsvar);\n"
        }

        #CGKS check [no isa] : body }
        elsif ($override eq "check" && !$hasisa && $delim eq ":" && $overridebody ne "") {
            $body .= "return (\n$overridebody\n);\n";
        }

        #CGKS change isa Foo [no body]
        elsif ($override eq "change" && $hasisa && $overridebody eq "") {
            $body .= $defaultbody;
        } 

        #CGKS change isa { curlybody }
        elsif ($override eq "change" && $hasisa && $delim eq "{") {
            $body .= $pre;
            $body .= "{\n$overridebody\n}";
            $body .= $post;
        }

        #CGKS change { curlybody }
        elsif ($override eq "change" && !$hasisa && $delim eq "{") {
            $body .= "{\n$overridebody\n}";
        }

        else {
            print STDERR "CGKS=$override($pre, $defaultbody, $post) [$overridebody] d($delim) isa($optisa)\n";
            $self->crash("UNHANDLED CODEGEN");
        }

        my $internal = $self->codegenMapDollaVars($body,$override,$overridesourceline,$selfvar);
        if (!defined $internal) {
            $self->crash("NO INTERNAL FOR($body,$override,$selfvar)");
        }
        print $out SPLATtr::prefixIndent("  ", $internal);
        print $out "  }\n";  # Close the method

#print STDERR "CGKS:".SPLATtr::prefixIndent("  ", $internal);
#         } elsif ($delim eq ":") {
#             my $internal = $self->codegenMapDollaVars($body,$override,$selfvar);
#             return unless defined $internal;
# print STDERR "nforb($internal)($body)/$override...\n";
#             if ($oi->{ReturnType} eq "Bool") {
#                 print $out SPLATtr::prefixIndent("    ", "return (\n   $internal\n   );\n");
#             } elsif ($oi->{ReturnType} eq "Votes") {
#                 my $code = <<EOC;
# if (
#     $internal
#    ) 
#   return 1u;
# return 0u;
# EOC
#                 print $out SPLATtr::prefixIndent("  ", $code);
#             } else {
#                 $self->{s}->printfError($self->{sourceLine},"%s","Cannot use '$delim' for $override override");
#                 return;
#             }
#         } elsif ($delim eq "=") {
#             $self->codegenKeyExprOverrideForKeySet($out, $optisa, $overridebody);
#         } else {
#             $self->crash("Unimplemented override delimiter '$delim' in '$origbody'");
#         }
#         print $out "  }\n";
    }

}

1; # SPLATtrNodeKeySet.pm
