package SPLATtrNodeSentence {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, $sline, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        $self->assertClass($sline,"SPLATSourceLine");
        $self->{sourceLines} = [$sline];  # a singleton source line unless continuations
        return bless($self,$class);
    }
    sub acceptIfContinuation {
        my ($self,$sline) = @_;
        $self->assertClass($sline,"SPLATSourceLine");
        my $text = $sline->getText();
        if ($text =~ /^[+.]/) {
            push @{$self->{sourceLines}}, $sline;
            return 1;
        }
        return 0;
    }
    sub getText {
        my ($self) = @_;
        my $text = undef;
        foreach my $sline (@{$self->{sourceLines}}) {
            my $t = $sline->getText();
            if (!defined $text) {
                $text = $t;
            } else {
                $text .= "\n".substr($t,1);
            }
        }
        $text .= "\n";
        return $text;
    }

    sub toMultilineString {
        my ($self,$lineprefix) = @_;
        my $ret = "";
        foreach my $sline (@{$self->{sourceLines}}) {
            my $t = $sline->getText();
            $ret .= $lineprefix;
            $ret .= $t;
        }
        return $ret;
    }

    sub isNonContinuationSententialLine {
        my ($text) = @_;
        return $text =~ /^[^+\s].*$/  # any non-blank non-space init is sentence starting
    }

    sub isContinuationSententialLine {
        my ($text) = @_;
        return $text =~ /^[+].*$/
    }

    sub newIfParse {
        my ($class, $s, $firstRegex) = @_;
        die unless defined $firstRegex;
        my $sline = $s->peekLine();
        my $text = $sline->getText();
        return undef unless isNonContinuationSententialLine($text);
        return undef unless $text =~ /$firstRegex/;
        my $self = $class->new($s,$sline);
        $self->{sourceLine} = $s->readLine();
        while ($self->acceptIfContinuation($s->peekLine())) {
            $s->readLine();
        }
        return $self;
    }

    sub analysisPhase {
        my ($self,@parents) = @_;

        for (my $s = 0; $s < scalar @{$self->{sourceLines}}; ++$s) {
            my $a = $self->{sourceLines}->[$s]->analysisPhase($self,@parents);
            return undef unless defined $a;
            $self->{sourceLines}->[$s] = $a;
        }
        return $self;
    }

    sub getPrefix {
        my ($self,$len) = @_;
        $len = 10 unless defined $len;
        my $text = $self->getText();
        chomp $text;
        return $text
            if length($text) <= $len;
        return substr($text,0,$len-2)."..";
    }

    sub getUlamText {  # return undef if not ulam sentence
        my ($self) = @_;
        my $text = $self->getText();
        chomp $text;
        if ($text =~ /^(u(lam)?)\s+(.*)$/s) {
            my ($verb,$rest) = ($1,$3);
            return $rest;
        }
        return undef;
    }

    #### KEY STATEMENT GRAMMAR
    ##
    #    KEY_STMT <- VERB KEY BODY EOS
    #        VERB <- "given" | "vote" | "check" | "change"
    #         KEY <- regex([a-zA-Z._@?])
    #       DELIM <- regex([:={])
    #        BODY <- ISA_BODY | DELIM_BODY
    #  DELIM_BODY <- | COLON_BODY | EQUALS_BODY | CURLY_BODY
    #    ISA_BODY <- "isa" ULAM_TYPE DELIM_BODY
    #
    #  COLON_BODY <- ":" ULAM_BOOL_EXPR
    # EQUALS_BODY <- "=" KEY_EXPR 
    #  CURLY_BODY <- "{" regex(.*) "}" EOS
    #
    #    KEY_EXPR <- KEY_FACTOR | KEY_EXPR "," KEY_FACTOR
    #  KEY_FACTOR <- KEY_TERM | KEY_FACTOR "|" KEY_TERM
    #    KEY_TERM <- KEY_UNOP | KEY_TERM "&" KEY_UNOP
    #   KEY_UNOP  <- KEY_IDENT | "~" KEY_UNOP
    #   KEY_IDENT <- KEY | "(" KEY_EXPR ")"
    ##
    ####
    sub readTok { return shift @{$_[0]}; }
    sub peekTok { return $_[0]->[0]; }
    sub matchTok { my ($want, $tr) = @_; if (peekTok($tr) eq $want) { readTok($tr); return 1; } return 0; }
    sub regexTok { my ($regex, $tr) = @_; my $ret = undef; if (peekTok($tr) =~ /($regex)/) { $ret = $1; readTok($tr); } return $ret; }
    sub isEOSTok { return peekTok(@_) eq "EOS" }
    sub restToks { return join("",@{$_[0]}); }
    sub printKeyExpr {
        my ($out, $tree) = @_;
        if (!defined($tree)) {
            print $out "UNDEF\n";
            return;
        }
        printKeyExprFPIF($out, $tree);
        print $out "\n";
    }
    sub printKeyExprDIE {
        my ($msg) = @_;
        print STDERR "Error: $msg\n";
        abort();
    }
    sub printKeyExprFPIF {
        my ($out, $tree) = @_;
        printKeyExprDIE("Bad arg '$tree'") unless ref $tree eq "ARRAY";
#        print STDERR "GOTS(".join(",",@{$tree}).")\n";
        my $len = scalar(@{$tree});
        printKeyExprDIE("Too short") unless $len > 1;
        if ($tree->[0] eq "key") {
            printKeyExprDIE("Too long") unless $len == 2;
            print $out "$tree->[1]";
            return;
        } 
        if ($tree->[0] eq "unop") {
            printKeyExprDIE("Bad size") unless $len == 3;
            print $tree->[1];
            print $out "(";
            printKeyExprFPIF($out, $tree->[2]);
            print $out ")";
            return;
        }
        printKeyExprDie("Bad long length") unless $len == 4;
        print $out "(";
        printKeyExprFPIF($out, $tree->[2]);
        print $out $tree->[1];
        printKeyExprFPIF($out, $tree->[3]);
        print $out ")";
    }

    sub parseTopLevelKeyExpr {
        my ($self,$tr) = @_;
        my $expr = $self->parseKeyExpr($tr);
        if (!isEOSTok($tr)) {
            $self->{s}->printfError($self->{sourceLine},"Not end after key expr '%s'", restToks($tr));
        }
        return $expr;
    }

    sub parseKeyExpr {
        my ($self,$tr) = @_;
        my $factor = $self->parseKeyFactor($tr);
        return undef unless $factor;
        while (matchTok(",",$tr)) {
            my $f2 = $self->parseKeyFactor($tr);
            $factor = ["expr", ",", $factor, $f2];
        } 
        return $factor;
    }
    sub parseKeyFactor {
        my ($self,$tr) = @_;
        my $term = $self->parseKeyTerm($tr);
        return undef unless $term;
        while (matchTok("|",$tr)) {
            my $t2 = $self->parseKeyTerm($tr);
            $term = ["factor", "|", $term, $t2];
        }
        return $term;
    }
    sub parseKeyTerm {
        my ($self,$tr) = @_;
        my $unop = $self->parseKeyUnop($tr);
        while (matchTok("&",$tr)) {
            my $u2 = $self->parseKeyUnop($tr);
            $unop = ["term", "&", $unop, $u2];
        }
        return $unop;
    }
    sub parseKeyUnop {
        my ($self,$tr) = @_;
        if (matchTok("~",$tr)) {
            my $unop = $self->parseKeyUnop($tr);
            return ["unop", "~", $unop];
        }
        return $self->parseKeyIdent($tr);
    }
    sub parseKeyIdent {
        my ($self,$tr) = @_;
        if (matchTok("(",$tr)) {
            my $expr = $self->parseKeyExpr($tr);
            return undef unless $expr;
            if (!matchTok(")",$tr)) {
                $self->{s}->printfError($self->{sourceLine},
                                        "Expected ')' in key expression, found %s", restToks($tr));
                return undef;
            }
            return $expr;
        }
        my $key = regexTok('[a-zA-Z._@?]',$tr);
        if (!defined $key) {
            $self->{s}->printfError($self->{sourceLine},"Expected keycode in key expression, found '%s'", restToks($tr));
            return undef;
        }
        return ["key", $key];
    }

    sub extractKeyCodes {
        my ($self,$ruleset) = @_;
        $self->crash("Bad arg") unless ref($ruleset) eq "SPLATtrNodeSectionSplatRules";
        my $text = $self->getText();
        chomp $text;
        ## Get VERB
        my $VERB;
        if ($text !~ /^(given|vote|check|change|let)\s+([^\s].*)$/s) {
            $self->{s}->printfError($self->{sourceLine},"Invalid statement type in '%s'",$text);
            return;
        }
        ($VERB,$text) = ($1,$2);

        ## Get KEY
        my $KEY;
        if ($text !~ /^([a-zA-Z._@?])\s+([^\s].*)$/s) {
            $self->{s}->printfError($self->{sourceLine},"Invalid key code in '%s'",$text);
            return;
        }
        ($KEY,$text) = ($1,$2);

        # (Get keyset for KEY)
        my $ks = $ruleset->getKeySet($KEY,$self->{sourceLine});

        # (Check multiple def)

        if (defined($ks->{overrides}->{$VERB})) {
            $self->{s}->printfError($self->{sourceLine},"Key code '%s' already has %s definition at %s",
                                    $KEY, $VERB, $ks->{sourceLine});
            return;
        }

        ## Get optional ISA type
        my $OPTISA = undef;
        if ($text =~ /^isa\s+([A-Z][A-Za-z_]*)\s*([^\s].*)?$/s) {
            ($OPTISA,$text) = ($1,$2);

            if (!defined($text) || $text =~ m!^//.*$!) { # isa was all of it, or with just a comment
                # So default in a colon body
                $ks->{overrides}->{$VERB} = [":", $OPTISA, ""];
                return;
            }
        }

        ## Handle CURLY_BODY
        if ($text =~ /^({)(.*)}$/s) {
            my ($delim, $CURLY_BODY) = ($1,$2);
            if ($VERB eq "let") {
                $self->{s}->printfError($self->{sourceLine},"'let %s' only accepts '= keyexpr', not '%s'",
                                        $KEY, $delim, $ks->{sourceLine});
                return;
            }
            $ks->{overrides}->{$VERB} = [$delim, $OPTISA, $CURLY_BODY];
            return;
        }

        ## Handle COLON_BODY
        if ($text =~ /^(:)\s*(.*)$/s) {
            my ($delim, $COLON_BODY) = ($1,$2);
            if ($VERB eq "let") {
                $self->{s}->printfError($self->{sourceLine},"'let %s' only accepts '= keyexpr', not '%s'",
                                        $KEY, $delim, $ks->{sourceLine});
                return;
            }
            $ks->{overrides}->{$VERB} = [$delim, $OPTISA, $COLON_BODY];
            return;
        }

        ## Handle EQUALS_BODY
        if ($text !~ /^(=)\s*(.*)$/s) {
            $self->{s}->printfError($self->{sourceLine},"Unrecognized statement delimiter '$text'");
            return;
        }
        my $delim;
        ($delim, $text) = ($1,$2);
        
        # First eat comments
        $text =~ s/#.*?$//mg;

        # 'Tokenize' the rest and append EOS
        my @toks = (split(/\s*/,$text), "EOS");

        my $EQUALS_BODY = $self->parseTopLevelKeyExpr(\@toks);
#        printKeyExpr(STDERR, $EQUALS_BODY);
        return unless defined $EQUALS_BODY;

        if ($VERB eq "let") {
            foreach my $v ("given", "vote") {  ## NOT CHANGE! STALE_ATOM_REF FOLLOWS THAT!
                $ks->{overrides}->{$v} = [$delim, $OPTISA, $EQUALS_BODY];
            }
            return;
        }

        $ks->{overrides}->{$VERB} = [$delim, $OPTISA, $EQUALS_BODY];

    }
}

1; # SPLATtrNodeSentence.pm
