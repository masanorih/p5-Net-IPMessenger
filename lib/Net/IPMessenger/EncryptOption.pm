package Net::IPMessenger::EncryptOption;

use warnings;
use strict;
use overload '""' => \&get_option, fallback => 1;
use Scalar::Util qw( looks_like_number );

our $VERSION = '0.01';
our $AUTOLOAD;

my %ENCRYPT_OPT = (
    RSA_512         => 0x00000001,
    RSA_1024        => 0x00000002,
    RSA_2048        => 0x00000004,
    RC2_40          => 0x00001000,
    RC2_128         => 0x00004000,
    RC2_256         => 0x00008000,
    BLOWFISH_128    => 0x00020000,
    BLOWFISH_256    => 0x00040000,
    SIGN_MD5        => 0x10000000,
    RC2_40OLD       => 0x00000010,
    RC2_128OLD      => 0x00000040,
    BLOWFISH_128OLD => 0x00000400,
);

sub new {
    my $class = shift;
    my $option = shift || 0;

    return unless looks_like_number($option);
    my $self = { _option => $option };
    bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;
    return unless ref $self;

    my $option = $self->{_option};
    my $name   = $AUTOLOAD;
    $name =~ s/.*://;

    if ( $name =~ /^get_(.+)/ ) {
        my $enc = uc $1;
        if ( exists $ENCRYPT_OPT{$enc} ) {
            return ( $option & $ENCRYPT_OPT{$enc} ? 1 : 0 );
        }
        else {
            return;
        }
    }
    elsif ( $name =~ /^set_(.+)/ ) {
        my $enc = uc $1;
        if ( exists $ENCRYPT_OPT{$enc} ) {
            $self->{_option} = $option | $ENCRYPT_OPT{$enc};
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

sub get_option {
    my $self = shift;
    return $self->{_option};
}

1;
__END__

=head1 NAME

Net::IPMessenger::EncryptOption - encrypt option definition


=head1 VERSION

This document describes Net::IPMessenger::EncryptOption version 0.01


=head1 SYNOPSIS

    use Net::IPMessenger::EncryptOption;

    my $option = Net::IPMessenger::EncryptOption->new;
    $option->set_rsa_1024->set_blowfish_128;

=head1 DESCRIPTION

This defines IP Messenger encrypt and option flags.
This also gives you accessors of those option flags.

=head1 METHODS

=head2 new

This creates object and return it.
if argument is given and it looks like number,
store it and use as default option value.


=head2 get_option

Returns option value.

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

=cut
