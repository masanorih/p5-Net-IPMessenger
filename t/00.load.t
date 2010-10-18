use Test::More tests => 7;

BEGIN {
use_ok( 'Net::IPMessenger' );
use_ok( 'Net::IPMessenger::ClientData' );
use_ok( 'Net::IPMessenger::CommandLine' );
use_ok( 'Net::IPMessenger::EventHandler' );
use_ok( 'Net::IPMessenger::MessageCommand' );
use_ok( 'Net::IPMessenger::RecvEventHandler' );
use_ok( 'Net::IPMessenger::ToStdoutEventHandler' );
}

diag( "Testing Net::IPMessenger $Net::IPMessenger::VERSION" );
