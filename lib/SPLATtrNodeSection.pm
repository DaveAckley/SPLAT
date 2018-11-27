package SPLATtrNodeSection {
    use parent "SPLATtrNode";
    our @ISA;
    sub new {
        my ($class, $splattr, %params) = @_;
        my $self = $ISA[0]->new($splattr, %params);
        %{$self} = (
            %{$self},
            sectionLevel => $params{sectionLevel},
            sectionDescriptor => $params{sectionDescriptor},
            sectionBlurb => $params{sectionBlurb},
            sectionSubsectionIndex => undef, # In our parent, set by our parent
            sectionBodyUnits => [],
            sectionBodySubsections => [],
            );
        $self->crash("Missing section level") unless defined $self->{sectionLevel};
        $self->crash("Bad section level $params{sectionLevel}") 
            unless $self->{sectionLevel} >= 0;
        return bless($self,$class);
    }

    sub analysisPhase {
        my ($self,@parents) = @_;
        my $errors = 0;
        for (my $u = 0; $u < scalar @{$self->{sectionBodyUnits}}; ++$u) {
            my $a = $self->{sectionBodyUnits}->[$u]->analysisPhase($self,@parents);
            if (defined($a)) {
                $self->{sectionBodyUnits}->[$u] = $a;
            } else {
                ++$errors;
            }
        }
        for (my $s = 0; $s < scalar @{$self->{sectionBodySubsections}}; ++$s) {
            my $a = $self->{sectionBodySubsections}->[$s]->analysisPhase($self,@parents);
            if (defined($a)) {
                $self->{sectionBodySubsections}->[$s] = $a;
            } else {
                ++$errors;
            }
        }

        if ($errors > 0) {
            return undef;
        }

        return $self;
    }

    sub tryParseSectionHeader { # Returns undef if no or (level, text) if yes (level 0 impossible here)
        my ($text) = @_;
       if ($text =~ /^(=+)\s+(.*?)\s*$/) {
            my ($sectag, $descriptor) = ($1, $2);
            return (length($sectag),$descriptor);
        }
        return undef;
    }


    sub newIfParse {
        my ($class, $s, $parentSectionLevel) = @_;
        my $sline = $s->peekLine();
        my ($level,$desc) = tryParseSectionHeader($sline->getText());
        return undef unless defined $level;
        return undef if $level <= $parentSectionLevel; # This is not our subsection

        # Analyze level and descriptor to determine what type of section to make
        my $classToMake;
        my $blurb = undef; # Possible extra text found case by case
        my %params;
        if ($level == 1) {
            # splat element and quark only thing supported to get us started
            my $text = $desc;
            if ($text =~ s/\s*(element|quark)\s+([A-Z][A-Za-z_0-9]*)\s*((\s+isa|:)\s+([^ ]+))?\s*(|[.]\s*(.*))$//) {
                my ($classType, $className, $isa, $superType, $rest) = ($1,$2,$4,$5,$7);
                if (defined $isa && $isa eq ":") {
                    $s->printfError($sline,"%s","Use 'isa', not ':', for SPLAT inheritance");
                    return undef;
                }
                if (!SPLATtr::legalUlamType($className)) {
                    $s->printfError($sline,"%s","Illegal type name '$className'");
                    return undef;
                }
                if (defined($superType)) {
                    if (!SPLATtr::legalUlamType($superType)) {
                        $s->printfError($sline,"%s","Illegal superclass type name '$superType'");
                        return undef;
                    }
                    $params{superClass} = $superType;
                }

                $blurb = $rest;
#          print STDERR "BLURBAGE='$blurb'\n" if defined $blurb;
                $classToMake = "SPLATtrNodeSectionSplatClass";
                $params{className} = $className;
                $params{classCategory} = $classType;
            } else {
                $s->printfError($sline,"%s","Unrecognized level 1 section: $text");
                return undef;
            }
        } elsif ($level == 2) {
            # Rules only thing supported to get us started
            # (Data members next)
            my $text = $desc;
            if ($text =~ s/\s*(pre|post)?\s*rules?\s*//i) {
                $params{ruleOrder} = lc($1 || "pre");
                $classToMake = "SPLATtrNodeSectionSplatRules";
                $blurb = $text;
            } elsif ($text =~ s/\s*data\s*members?\s*//i) {
                $classToMake = "SPLATtrNodeSectionSplatDataMembers";
                $blurb = $text;
            } elsif ($text =~ s/\s*methods?\s*//i) {
                $classToMake = "SPLATtrNodeSectionSplatMethods";
                $blurb = $text;
            } else {
                $s->printfError($sline,"%s","Unrecognized level 2 section: $text");
                return undef;
            }
        } else {
            $s->printfError($sline,"%s","Unrecognized level $level section: $desc");
            return undef;
        }

        my $self = $classToMake->new($s, 
                                     sectionLevel => $level,
                                     sectionDescriptor => $desc,
                                     sectionBlurb => $blurb,
                                     %params,
            );
        $self->{sourceLine} = $s->readLine(); # First line represents the section
        $self->parseSectionBody();
        return $self;
    }

    sub parseSectionBody {
        my ($self) = @_;
        while (my $unit = SPLATtrNodeUnit->newIfParse($self->{s})) {
            $unit->{sectionUnitIndex} = scalar(@{$self->{sectionBodyUnits}});
            push @{$self->{sectionBodyUnits}}, $unit;
        }
        while (my $unit = SPLATtrNodeSection->newIfParse($self->{s}, $self->{sectionLevel})) {
            $unit->{sectionSubsectionIndex} = scalar(@{$self->{sectionBodySubsections}});
            push @{$self->{sectionBodySubsections}}, $unit;
        }
        return $self;
    }

    sub codegenPhase {
        my ($self,@parents) = @_;
        # Skip the units and codegen the subsections, if nothing better to do
        for (my $s = 0; $s < scalar @{$self->{sectionBodySubsections}}; ++$s) {
            my $a = $self->{sectionBodySubsections}->[$s]->codegenPhase($self,@parents);
            return 0 unless $a;
        }
        return 1; 
    }

}

1; # SPLATtrNodeSection.pm
