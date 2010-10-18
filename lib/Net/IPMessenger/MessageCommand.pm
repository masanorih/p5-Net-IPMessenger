package Net::IPMessenger::MessageCommand;

use warnings;
use strict;
use overload '""' => \&get_command, fallback => 1;
use Scalar::Util qw( looks_like_number );

our $VERSION = '0.04';
our $AUTOLOAD;

my %COMMAND = (
    NOOPERATION     => 0x00000000,
    BR_ENTRY        => 0x00000001,
    BR_EXIT         => 0x00000002,
    ANSENTRY        => 0x00000003,
    BR_ABSENCE      => 0x00000004,
    BR_ISGETLIST    => 0x00000010,
    OKGETLIST       => 0x00000011,
    GETLIST         => 0x00000012,
    ANSLIST         => 0x00000013,
    BR_ISGETLIST2   => 0x00000018,
    SENDMSG         => 0x00000020,
    RECVMSG         => 0x00000021,
    READMSG         => 0x00000030,
    DELMSG          => 0x00000031,
    ANSREADMSG      => 0x00000032,
    GETINFO         => 0x00000040,
    SENDINFO        => 0x00000041,
    GETABSENCEINFO  => 0x00000050,
    SENDABSENCEINFO => 0x00000051,
    GETFILEDAT      => 0x00000060,
    RELEASEFIL      => 0x00000061,
    GETDIRFILE      => 0x00000062,
    GETPUBKEY       => 0x00000072,
    ANSPUBKEY       => 0x00000073,
);

my $MODE     = 0x000000ff;
my %SEND_OPT = (
    ABSENCE    => 0x00000100,
    SERVER     => 0x00000200,
    DIALUP     => 0x00010000,
    SENDCHECK  => 0x00000100,
    SECRET     => 0x00000200,
    BROADCAST  => 0x00000400,
    MULTICAST  => 0x00000800,
    NOPOPUP    => 0x00001000,
    AUTORET    => 0x00002000,
    RETRY      => 0x00004000,
    PASSWORD   => 0x00008000,
    NOLOG      => 0x00020000,
    NEWMUTI    => 0x00040000,
    NOADDLIST  => 0x00080000,
    READCHECK  => 0x00100000,
    FILEATTACH => 0x00200000,
    ENCRYPT    => 0x00400000,
);

sub new {
    my $class = shift;
    my $name  = shift;
    return unless defined $name;

    my $command;
    if ( looks_like_number($name) ) {
        $command = $name;
    }
    elsif ( exists $COMMAND{$name} ) {
        $command = $COMMAND{$name};
    }
    else {
        return;
    }

    my $self = { _command => $command };
    bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;
    return unless ref $self;

    my $command = $self->{_command};
    my $name    = $AUTOLOAD;
    $name =~ s/.*://;

    if ( $name =~ /^get_(.+)/ ) {
        my $opt = uc $1;
        if ( exists $SEND_OPT{$opt} ) {
            return ( $command & $SEND_OPT{$opt} ? 1 : 0 );
        }
        else {
            return;
        }
    }
    elsif ( $name =~ /^set_(.+)/ ) {
        my $opt = uc $1;
        if ( exists $SEND_OPT{$opt} ) {
            $self->{_command} = $command | $SEND_OPT{$opt};
            return $self;
        }
        else {
            return;
        }
    }
    else {
        return;
    }
}

sub mode {
    my $self    = shift;
    my $command = $self->{_command};

    return (0) unless defined $command;
    return ( $command & $MODE );
}

sub modename {
    my $self = shift;
    my $mode = $self->mode;

    for my $key ( keys %COMMAND ) {
        if ( $mode eq $COMMAND{$key} ) {
            return $key;
        }
    }
    return $mode;
}

sub get_command {
    my $self = shift;
    return $self->{_command};
}

sub DESTROY {
}

1;
__END__

=head1 NAME

Net::IPMessenger::MessageCommand - message command definition and accessor class

=head1 VERSION

This document describes Net::IPMessenger::MessageCommand version 0.04


=head1 SYNOPSIS

    use Net::IPMessenger::MessageCommand;

    my $command = Net::IPMessenger::MessageCommand->new('SENDMSG')->set_secret;


=head1 DESCRIPTION

This defines IP Messenger command and option flags.
This also gives you accessors of those option flags.


=head1 METHODS

Option flag accessors are provided via AUTOLOAD method.
you can use get_*, set_* to access those option flags.

=head2 new

    my $messagecommand = Net::IPMessenger::MessageCommand->new($command);

Creates object and stores command. If command looks like number, just stores it.
Otherwise, tries to convert it by using %COMMAND.

=head2 mode

    my $mode = $messagecommand->mode;

Returns command mode part.

=head2 modename

    my $modename = $messagecommand->modename;

Returns command modename.

=head2 get_command

    my $command = $messagecommand->get_command;

Just returns stored command value.


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
