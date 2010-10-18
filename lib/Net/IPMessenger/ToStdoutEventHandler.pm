package Net::IPMessenger::ToStdoutEventHandler;

use warnings;
use strict;
use Encode qw( from_to );
use IO::Socket;
use POSIX;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use base qw( Net::IPMessenger::EventHandler );

our $VERSION = '0.04';

sub output {
    my $str = shift;
    from_to($str, 'shiftjis', 'euc-jp');
    my $time = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print YELLOW "At \"$time\", " . $str;
    print RESET "\n";
}

sub debug {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    my $peeraddr = inet_ntoa( $them->socket->peeraddr );
    my $peerport = $them->socket->peerport;
    my $command  = $them->messagecommand( $user->command );
    my $modename = $command->modename;

    print CYAN "Received $modename from [$peeraddr:$peerport]";
    print RESET "\n";
}

sub BR_ENTRY {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output($user->nickname . " joined.");
}

sub BR_EXIT {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output($user->nickname . " left.");
}

sub SENDMSG {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output("you got message from " . $user->nickname . " .\a");
}

1;
__END__

=head1 NAME

Net:IPMessenger::ToStdoutEventHandler - event handler for standard output


=head1 VERSION

This document describes Net::IPMessenger::ToStdoutEventHandler version 0.04


=head1 SYNOPSIS

    use Net::IPMessenger::ToStdoutEventHandler;

    ...

    $ipmsg->add_event_handler( new Net::IPMessenger::ToStdoutEventHandler );


=head1 DESCRIPTION

IP Messenger receive event handler for standard output.


=head1 METHODS

=head2 output

    output($user->nickname . " joined.");

This actually converts encodings and output to STDOUT.

=head2 debug

Outputs debug receive message.

=head2 BR_ENTRY

Outputs "someone joined." message.

=head2 BR_EXIT

Outputs "someone left." message.

=head2 SENDMSG

Outputs "you've got message from someone." message.


=head1 SEE ALSO

L<Net::IPMessenger::EventHandler>


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
