package Net::IPMessenger::Encrypt;

use warnings;
use strict;
use Net::IPMessenger::EncryptOption;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( exponent modulus private_key support_encryption ));

our $VERSION     = '0.01';
my $RSA_KEY_SIZE = 1024;
my $IV           = "\0\0\0\0\0\0\0\0";

sub new {
    my $class = shift;
    my %args  = @_;

    # needs those modules for encryption support
    eval {
        require Crypt::Blowfish;
        require Crypt::CBC;
        require Crypt::OpenSSL::Bignum;
        require Crypt::OpenSSL::RSA;
    };

    return if $@;
    my $self = {};
    bless $self, $class;

    $self->support_encryption( $self->option->set_rsa_1024->set_blowfish_128 );
    return $self;
}

sub option {
    my $self = shift;
    return Net::IPMessenger::EncryptOption->new(shift);
}

sub generate_keys {
    my $self = shift;

    if ( $self->private_key ) {
        return ( $self->exponent, $self->modulus );
    }

    my $rsa_key_size;
    my $option = $self->support_encryption;
    if ( $option->get_rsa_2048 ) {
        $rsa_key_size = 2048;
    }
    elsif ( $option->get_rsa_1024 ) {
        $rsa_key_size = 1024;
    }
    elsif ( $option->get_rsa_512 ) {
        $rsa_key_size = 512;
    }

    my $rsa = Crypt::OpenSSL::RSA->generate_key($rsa_key_size);
    my( $modulus, $exponent ) = $rsa->get_key_parameters;

    $self->private_key( $rsa->get_private_key_string );
    return (
        $self->exponent( $exponent->to_hex ),
        $self->modulus( $modulus->to_hex )
    );
}

sub public_key_string {
    my $self = shift;

    my( $exponent, $modulus ) = $self->generate_keys;
    my $option = sprintf "%x:%d-%s",
        $self->support_encryption, $exponent, $modulus;
}

sub encrypt_message {
    my $self    = shift;
    my $message = shift;
    my $pubkey  = shift;

    my $option = $self->option( hex $pubkey->{option} );
    my $blowfish_key_size;
    if ( $option->get_blowfish_128 ) {
        $blowfish_key_size = 128 / 8;
    }
    elsif ( $option->get_blowfish_256 ) {
        $blowfish_key_size = 256 / 8;
    }

    my $shared_key = Crypt::CBC->random_bytes($blowfish_key_size);
    my $blowfish   = Crypt::CBC->new(
        -literal_key => 1,
        -key         => $shared_key,
        -keysize     => length $shared_key,
        -cipher      => 'Blowfish',
        -padding     => 'standard',
        -iv          => $IV,
        -header      => 'none',
    );

    my $exponent = Crypt::OpenSSL::Bignum->new_from_hex( $pubkey->{exponent} );
    my $modulus  = Crypt::OpenSSL::Bignum->new_from_hex( $pubkey->{modulus} );
    my $rsa_pub =
        Crypt::OpenSSL::RSA->new_key_from_parameters( $modulus, $exponent );
    $rsa_pub->use_pkcs1_padding;

    # encrypt key and message
    my $cipher_key  = $rsa_pub->encrypt($shared_key);
    my $cipher_text = $blowfish->encrypt($message);

    return sprintf "%s:%s:%s", $pubkey->{option}, unpack( "H*", $cipher_key ),
        unpack( "H*", $cipher_text );
}

sub decrypt_message {
    my $self    = shift;
    my $message = shift;

    return $message unless defined $self->private_key;

    my( $enc_opt, $cipher_key, $cipher_text ) = split /\:/, $message;
    my $rsa = Crypt::OpenSSL::RSA->new_private_key( $self->private_key );
    $rsa->use_pkcs1_padding;
    my $shared_key = $rsa->decrypt( pack( "H*", $cipher_key ) );
    my $blowfish = Crypt::CBC->new(
        -literal_key => 1,
        -key         => $shared_key,
        -keysize     => length $shared_key,
        -cipher      => 'Blowfish',
        -padding     => 'standard',
        -iv          => $IV,
        -header      => 'none',
    );
    my $decrypted = $blowfish->decrypt( pack( "H*", $cipher_text ) );
    # windows client add null string so delete it
    my($plain_text) = split /\0/, $decrypted;
    return $plain_text;
}

1;
__END__

=head1 NAME

Net::IPMessenger::Encrypt - Encryption support for Net::IPMessenger


=head1 VERSION

This document describes Net::IPMessenger::Encrypt version 0.01


=head1 DESCRIPTION

Encryption support for Net::IPMessenger.


=head1 METHODS

=head2 new

The new method checks if the modules which needs for encryption are installed.
If those modules are not installed, this returns undef.

=head2 option

This returns Net::IPMessenger::EncryptOption object.

=head2 generate_keys

This generates RSA public/private keys and store it.

=head2 public_key_string

format public_key for ANSPUBKEY option field and return it.

=head2 encrypt_message

Encrypt message.

=head2 decrypt_message

Decrypt message.

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
