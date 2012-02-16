use Test::More;
use lib '../lib';
use Net::IPMessenger::Encrypt;

{
    my $encrypt = Net::IPMessenger::Encrypt->new;
    if ( not $encrypt ) {
        plan skip_all => 'skip encrypt test. failed to new encrypt module';
    }
}
{
    # no base64
    for my $i ( 1 .. 10 ) {
        my $encrypt = Net::IPMessenger::Encrypt->new;
        is $encrypt->support_encryption->get_encode_base64, 0,
            'default not base64 supported';
        run_tests( $encrypt, $i );
    }
    # base64
    for my $i ( 1 .. 10 ) {
        my $encrypt = Net::IPMessenger::Encrypt->new;
        $encrypt->support_encryption->set_encode_base64;
        is $encrypt->support_encryption->get_encode_base64, 1,
            'base64 supported';
        run_tests( $encrypt, $i );
    }
}
done_testing;

sub run_tests {
    my( $self, $i ) = @_;

    my $option = $self->support_encryption;
    my ( $exponent, $modulus ) = $self->generate_keys;
    my $pubkey = {
        exponent => $exponent,
        modulus  => $modulus,
        option   => $option,
    };
    encode_message( $self, $pubkey, $i );
}

sub encode_message {
    my( $self, $pubkey, $i ) = @_;
    my $raw = scalar localtime;
    my $enc = $self->encrypt_message( $raw, $pubkey, $i );
    my $dec = $self->decrypt_message( $enc, $i );
    is $dec, $raw, 'encode -> decode do not change text';
}
