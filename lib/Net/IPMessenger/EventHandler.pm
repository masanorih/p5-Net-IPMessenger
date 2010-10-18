package Net::IPMessenger::EventHandler;

use warnings;
use strict;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    bless {}, $class;
}

sub add_callback {
    my $self = shift;
    my $name = shift;
    my $sub  = shift;

    $self->{callback}->{$name} = $sub;
}

sub callback {
    my $self = shift;
    my $name = shift;

    if ( exists $self->{callback}->{$name} ) {
        return $self->{callback}->{$name};
    }
    return;
}

1;
__END__

=head1 NAME

Net::IPMessenger::EventHandler - IP Messenger event handler base class.


=head1 VERSION

This document describes Net::IPMessenger::EventHandler version 0.02


=head1 SYNOPSIS

First of all, creates your event handler.

    package MyEventHandler;
    use base qw /Net::IPMessenger::EventHandler/;

    sub BR_ENTRY {
        my $self = shift;
        my $them = shift;
        my $user = shift;
        ...
    }

Next, add your event handler in the script.

    #!/usr/bin/perl

    use Net::IPMessenger;
    use MyEventHandler;

    my $ipmsg = Net::IPMessenger->new(
        ...
    );

    $ipmsg->add_event_handler( new MyEventHandler );

Then you receive a message, your handler method is invoked.


=head1 DESCRIPTION

This is a base event handler of Net::IPMessenger.

If you create method which name is same as 
%Net::IPMessenger::MessageCommand::COMMAND values name,
it will be invoked as you receive a message.

=head1 METHODS

=head2 new

Just creates object.

=head2 add_callback

    $self->add_callback( $name, \&sub );

Adds callback subroutine &sub and registers name $name.

=head2 callback

    goto $self->callback($name);

does callback $name.

=head1 SEE ALSO

L<Net::IPMessenger::RecvEventHandler>, L<Net::IPMessenger::ToStdoutEventHandler>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-net-ipmessenger@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Masanori Hara  C<< <massa.hara at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Masanori Hara C<< <massa.hara at gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
