package SPLAT;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::Splattr - Translator for SPLAT (Spatial Programming Language, Ascii Text)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

NOTE THIS MODULE CURRENTLY HAS *NO* *EXPOSED* *API* SO THIS DOC ISN'T WORTH MUCH

USE SPLATTR FROM THE COMMAND LINE

    $ ../splattr Foo.splat
    $ mfzrun a.mfz

(and watch it die unless the installed mfm/mfzrun is way new enough
for all this.)

Under development documention for SPLAT as a perl module.  But it's
really not meant to be a perl module, it's meant to be a, um,
compiler.  So it's unclear how developed this doc here will ever
really get.

But it's not developed now.

Perhaps a little code snippet.

    use SPLAT;

    my $foo = SPLAT->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Dave Ackley, C<< <ackley at ackleyshack.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-splat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SPLAT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SPLAT


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SPLAT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SPLAT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SPLAT>

=item * Search CPAN

L<http://search.cpan.org/dist/SPLAT/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Dave Ackley.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of SPLAT
