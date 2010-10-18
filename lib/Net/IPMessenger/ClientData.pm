package Net::IPMessenger::ClientData;

use warnings;
use strict;
use POSIX;
use Net::IPMessenger::MessageCommand;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(
    qw(
        version         packet_num      user            host
        command         option          nick            group
        peeraddr        peerport        listaddr        time
        pubkey          encrypt
        )
);

our $VERSION = '0.04';
my $NO_NAME  = '(noname)';
my $NO_GROUP = '(nogroup)';

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};
    bless $self, $class;

    $self->version( $args{Ver} )          if $args{Ver};
    $self->packet_num( $args{PacketNum} ) if $args{PacketNum};
    $self->user( $args{User} )            if $args{User};
    $self->host( $args{Host} )            if $args{Host};
    $self->command( $args{Command} )      if $args{Command};
    $self->nick( $args{Nick} )            if $args{Nick};
    $self->group( $args{Group} )          if $args{Group};
    $self->peeraddr( $args{PeerAddr} )    if $args{PeerAddr};
    $self->peerport( $args{PeerPort} )    if $args{PeerPort};
    $self->listaddr( $args{ListAddr} )    if $args{ListAddr};
    $self->time( strftime "%Y-%m-%d %H:%M:%S", localtime(time) );

    # some clients set "BS" in the GROUP so deletes it
    if ( $self->group and $self->group eq "\x08" ) {
        $self->group($NO_GROUP);
    }

    if ( exists $args{Message} ) {
        $self->parse( $args{Message} );
    }
    return $self;
}

sub parse {
    my $self    = shift;
    my $message = shift;

    my( $ver, $packet_num, $user, $host, $command, $option ) =
        split /:/, $message, 6;

    $self->version($ver);
    $self->packet_num($packet_num);
    $self->user($user);
    $self->host($host);
    $self->command($command);
    $self->option($option);
    $self->time( strftime "%Y-%m-%d %H:%M:%S", localtime(time) );
    $self->update_nickname;
}

sub update_nickname {
    my $self = shift;

    my $command  = Net::IPMessenger::MessageCommand->new( $self->command );
    my $modename = $command->modename;
    if ( $modename eq 'BR_ENTRY' or $modename eq 'ANSENTRY' ) {
        my( $nick, $group ) = ( $self->option =~ /(.*?)\0(.*?)\0/o );

        $self->nick($nick)   if defined $nick;
        $self->group($group) if defined $group;
        $self->encrypt( $command->get_encrypt );
    }
}

# Accessors

sub nickname {
    my $self = shift;
    return sprintf "%s\@%s", $self->nick || $self->user || $NO_NAME,
        $self->group || $self->host || $NO_GROUP;
}

sub key {
    my $self = shift;
    return sprintf "%s\@%s:%s", $self->user, $self->peeraddr, $self->peerport;
}

sub get_message { shift->option; }

1;
__END__

=head1 NAME

Net::IPMessenger::ClientData - IP Messenger client(message) class


=head1 VERSION

This document describes Net::IPMessenger::ClientData version 0.04


=head1 SYNOPSIS

    use Net::IPMessenger::ClientData;

    my $user = Net::IPMessenger::ClientData->new(
        Message  => $msg,
        PeerAddr => $peeraddr,
        PeerPort => $peerport,
    );
    my $key = $user->key;

=head1 DESCRIPTION

Converts IP Messenger message to the client object.

=head1 METHODS

=head2 new

    my $user = Net::IPMessenger::ClientData->new(
        Message  => $msg,
        PeerAddr => $peeraddr,
        PeerPort => $peerport,
    );

Creates object and parse message if there is message.

=head2 parse

    $self->parse($message);

Parses a message string and stores to the accessor.

=head2 update_nickname

    $self->update_nickname;

Converts option to the nickname, groupname.

=head2 nickname

    my $nickname = $self->nickname;

Retrieves nickname.

=head2 key

    my $key = $self->key;

Retrieves unique client key.

=head2 get_message

    my $meesage = $self->get_message;

Retrieves option as message.


=head1 CONFIGURATION AND ENVIRONMENT

Net::IPMessenger::ClientData requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


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
