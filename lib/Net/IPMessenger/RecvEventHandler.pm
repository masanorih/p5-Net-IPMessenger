package Net::IPMessenger::RecvEventHandler;

use warnings;
use strict;
use IO::Socket;
use base qw( Net::IPMessenger::EventHandler );

our $VERSION = '0.05';

sub BR_ENTRY {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    my $command = $ipmsg->messagecommand('ANSENTRY');
    $command->set_encrypt if $ipmsg->encrypt;
    $ipmsg->send(
        {
            command => $command,
            option  => $ipmsg->my_info,
        }
    );
}

sub ANSLIST {
    my $self     = shift;
    my $ipmsg    = shift;
    my $user     = shift;
    my $key      = $user->key;
    my $peeraddr = inet_ntoa( $ipmsg->socket->peeraddr );

    $ipmsg->parse_anslist( $user, $peeraddr );
    delete $ipmsg->user->{$key};
}

sub SENDMSG {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    my $command = $ipmsg->messagecommand( $user->command );
    if ( $command->get_sendcheck ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('RECVMSG'),
                option  => $user->packet_num,
            }
        );
    }

    # decrypt message if the message is encrypted
    # and encryption support is available
    if ( $command->get_encrypt and $ipmsg->encrypt ) {
        my $decrypted = $ipmsg->encrypt->decrypt_message( $user->get_message );
        $user->option($decrypted);
    }
    push @{ $ipmsg->message }, $user;
}

sub RECVMSG {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    my $option = $user->option;
    $option =~ s/\0//g;
    if ( exists $ipmsg->sending_packet->{$option} ) {
        delete $ipmsg->sending_packet->{$option};
    }
}

sub READMSG {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    my $command = $ipmsg->messagecommand( $user->command );
    if ( $command->get_readcheck ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('ANSREADMSG'),
                option  => $user->packet_num,
            }
        );
    }
}

sub GETINFO {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    $ipmsg->send(
        {
            command => $ipmsg->messagecommand('SENDINFO'),
            option  => sprintf( "Net::IPMessenger-%s", $ipmsg->VERSION ),
        }
    );
}

sub GETPUBKEY {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    return unless $ipmsg->encrypt;

    $ipmsg->send(
        {
            command => $ipmsg->messagecommand('ANSPUBKEY'),
            option  => $ipmsg->encrypt->public_key_string,
        }
    );
}

sub ANSPUBKEY {
    my $self  = shift;
    my $ipmsg = shift;
    my $user  = shift;

    return unless $ipmsg->encrypt;

    my $key     = $user->key;
    my $message = $user->get_message;
    my( $option, $public_key ) = split /:/,  $message;
    my( $exponent, $modulus )  = split /\-/, $public_key;
    $ipmsg->user->{$key}->pubkey(
        {
            option   => $option,
            exponent => $exponent,
            modulus  => $modulus,
        }
    );
}

1;
__END__

=head1 NAME

Net::IPMessenger::RecvEventHandler - default event handler


=head1 VERSION

This document describes Net::IPMessenger::RecvEventHandler version 0.04


=head1 SYNOPSIS

    use Net::IPMessenger::RecvEventHandler;

    ...

    $self->add_event_handler( new Net::IPMessenger::RecvEventHandler );

    use Net::IPMessenger::RecvEventHandler;


=head1 DESCRIPTION

IP Messenger receive event handler.
This is added default by Net::IPMessenger.

=head1 METHODS

=head2 BR_ENTRY

Replies ANSENTRY packet.

=head2 BR_EXIT

Deletes user from the user HASH.

=head2 ANSLIST

Parses message and deletes user from the user HASH
(because user is an exchange server).

=head2 SENDMSG

Replies RECVMSG packet if the message has SENDCHECK flag.
And adds message to the message ARRAY.

=head2 RECVMSG

Compare received message option field with messages in the queue.
If matchs found, delete the message in the queue.

=head2 READMSG

Replies ANSREADMSG packet if the message has READCHECK flag.

=head2 GETINFO

Replies SENDINFO packet. Version message is "Net::IPMessenger-version".

=head2 GETPUBKEY

Replies ANSPUBKEY packet.

=head2 ANSPUBKEY

Gets RSA public key and store it.

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
