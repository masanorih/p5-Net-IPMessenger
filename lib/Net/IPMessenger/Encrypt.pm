package Net::IPMessenger::Encrypt;

use warnings;
use strict;
use MIME::Base64 qw( encode_base64 decode_base64 );
use Net::IPMessenger::EncryptOption;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(
    qw( exponent modulus private_key
        support_encryption attach support_aes )
);

use constant IV => "\0\0\0\0\0\0\0\0";

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

    eval {
        require Crypt::GCrypt;
    };
    $self->support_aes(1) unless $@;
#   warn "support_aes = " . $self->support_aes . "\n";

#   my $option = $self->option->set_rsa_1024->set_blowfish_128;
#   my $option = $self->option->set_rsa_1024->set_blowfish_128->set_encode_base64;
#   my $option = $self->option->set_rsa_1024->set_blowfish_128->set_packetno_iv;
    my $option = $self->option->set_rsa_2048->set_aes_256->set_packetno_iv;
    $self->support_encryption($option);
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
    my( $self, $message, $pubkey, $packet_num ) = @_;

    my $option = $pubkey->{option};
    if ( 'Net::IPMessenger::EncryptOption' ne ref $option ) {
        $option = $self->option( hex $pubkey->{option} );
    }
    # use Data::Dumper; warn Dumper $option->dumpref;

    # on 3.31 windows2000
    #$VAR1 = {
    #    'SIGN_MD5'        => 0,
    #    'RC2_40OLD'       => 0,
    #    'BLOWFISH_128OLD' => 0,
    #    'PACKETNO_IV'     => 1,
    #    'RC2_40'          => 1,
    #    'SIGN_SHA1'       => 0,
    #    'RC2_128OLD'      => 0,
    #    'RSA_512'         => 1,
    #    'RSA_1024'        => 1,
    #    'AES_256'         => 0,
    #    'BLOWFISH_256'    => 0,
    #    'RSA_2048'        => 0,
    #    'BLOWFISH_128'    => 1,
    #    'RC2_256'         => 0,
    #    'RC2_128'         => 0,
    #    'ENCODE_BASE64'   => 0
    #};
    # on 3.10 windows7 home premium
    #$VAR1 = {
    #    'SIGN_MD5'        => 0,
    #    'RC2_40OLD'       => 0,
    #    'BLOWFISH_128OLD' => 0,
    #    'PACKETNO_IV'     => 1,
    #    'RC2_40'          => 1,
    #    'SIGN_SHA1'       => 1,    XXX
    #    'RC2_128OLD'      => 0,
    #    'RSA_512'         => 1,
    #    'RSA_1024'        => 1,
    #    'AES_256'         => 1,    XXX
    #    'BLOWFISH_256'    => 0,
    #    'RSA_2048'        => 1,    XXX
    #    'BLOWFISH_128'    => 1,
    #    'RC2_256'         => 0,
    #    'RC2_128'         => 0,
    #    'ENCODE_BASE64'   => 1     XXX
    #};
    # on 3.32 windows7
    #$VAR1 = {
    #    'SIGN_MD5'        => 0,
    #    'RC2_40OLD'       => 0,
    #    'BLOWFISH_128OLD' => 0,
    #    'PACKETNO_IV'     => 1,
    #    'RC2_40'          => 1,
    #    'SIGN_SHA1'       => 1,    XXX
    #    'RC2_128OLD'      => 0,
    #    'RSA_512'         => 1,
    #    'RSA_1024'        => 1,
    #    'AES_256'         => 1,    XXX
    #    'BLOWFISH_256'    => 0,
    #    'RSA_2048'        => 1,    XXX
    #    'BLOWFISH_128'    => 1,
    #    'RC2_256'         => 0,
    #    'RC2_128'         => 0,
    #    'ENCODE_BASE64'   => 1     XXX
    #};
    # set default keysize, algorithm
    my $keysize = 128 / 8;
    if ( $option->get_blowfish_256 ) {
        $keysize = 256 / 8; # 32 bytes
    }

    my $iv     = $self->generate_iv( $option, $packet_num );
    my $key    = Crypt::CBC->random_bytes($keysize);
    my $cipher = $self->generate_cipher( $option, $key, $iv, 'encrypting' );

    my $exponent = Crypt::OpenSSL::Bignum->new_from_hex( $pubkey->{exponent} );
    my $modulus  = Crypt::OpenSSL::Bignum->new_from_hex( $pubkey->{modulus} );
    my $rsa_pub =
        Crypt::OpenSSL::RSA->new_key_from_parameters( $modulus, $exponent );
    $rsa_pub->use_pkcs1_padding;

    # encrypt key and message
    my $cipher_key  = $rsa_pub->encrypt($key);
    my $cipher_text = $cipher->encrypt($message);
    $cipher_text .= $cipher->finish if $self->support_aes;
    if ( $option->get_encode_base64 ) {
        warn "encrypt base64";
        $cipher_key  = encode_base64( $cipher_key,  '' );
        $cipher_text = encode_base64( $cipher_text, '' );
    }
    else {
        $cipher_key  = unpack 'H*', $cipher_key;
        $cipher_text = unpack 'H*', $cipher_text;
    }
    $cipher_text .= "\0" if $self->support_aes;
    return sprintf "%s:%s:%s", $pubkey->{option}, $cipher_key, $cipher_text;
}

sub decrypt_message {
    my( $self, $message, $packet_num ) = @_;
    return $message unless defined $self->private_key;

    my( $enc_opt, $cipher_key, $cipher_text ) = split /\:/, $message, 3;
    my $rsa = Crypt::OpenSSL::RSA->new_private_key( $self->private_key );
    $rsa->use_pkcs1_padding;

    my $option = $self->support_encryption;

    #   use Data::Dumper; warn Dumper $option->dumpref;
    if ( $option->get_encode_base64 ) {
        $cipher_key = decode_base64($cipher_key);
    }
    else {
        $cipher_key = pack 'H*', $cipher_key;
    }
    my $key = $rsa->decrypt($cipher_key);
    my $iv  = $self->generate_iv( $option, $packet_num );
    my $cipher = $self->generate_cipher( $option, $key, $iv, 'decrypting' );
    #warn unpack 'H*', $cipher_text;
    chop $cipher_text if $self->support_aes; # XXX chop null

    # XXX attach info not encrypted
    my( $fileid, $attach ) = split /:/, $cipher_text, 2;
    $fileid = substr $fileid, -1;
    $attach = $fileid . ':' . $attach if $attach;

    if ( $option->get_encode_base64 ) {
        $cipher_text = decode_base64($cipher_text);
    }
    else {
        $cipher_text = pack 'H*', $cipher_text;
    }
    my $decrypted = $cipher->decrypt($cipher_text);
    $decrypted .= $cipher->finish if $self->support_aes;

    # delete null string
    my($text) = split /\0/, $decrypted;
    $self->attach($attach);
    return $text;
}

sub generate_iv {
    my( $self, $option, $packet_num ) = @_;
    my $iv = IV;
    if ( $option->get_packetno_iv ) {
        my $iv_size = length $iv;
        $iv = $packet_num;
        if ( $iv_size < length $iv ) {
            $iv = substr( $iv, 0, $iv_size );
        }
        else {
            while ( $iv_size > length $iv ) {
                $iv .= "\0";
            }
        }
    }
    return $iv;
}

sub generate_cipher {
    my( $self, $option, $key, $iv, $start ) = @_;
    my $cipher;
    if ( $option->get_aes_256 and $self->support_aes ) {
        $cipher = Crypt::GCrypt->new(
            type      => 'cipher',
            padding   => 'standard',
            algorithm => 'aes256',
            mode      => 'cbc',
        );
        $cipher->start($start);
        $cipher->setkey($key);
        $cipher->setiv($iv);
        #warn "cipher is Crypt::GCrypt\n";
    }
    else {
        $cipher = Crypt::CBC->new(
            -literal_key => 1,
            -key         => $key,
            -keysize     => length $key,
            -cipher      => 'Blowfish',
            -padding     => 'standard',
            -iv          => $iv,
            -header      => 'none',
        );
    }
    return $cipher;
}

1;
__END__

=head1 NAME

Net::IPMessenger::Encrypt - Encryption support for Net::IPMessenger

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
