#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
package main;

use lib './blib/lib','./lib';
use vars qw($OS_win $port %config_parms);

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..23\n";
        $OS_win = ($^O eq "MSWin32") ? 1 : 0;

            # This must be in a BEGIN in order for the 'use' to be conditional
        if ($OS_win) {
            eval "use Win32::SerialPort 0.17";
	    die "not ok 1\n$@\n" if ($@);

        }
        else {
            eval "use Device::SerialPort 0.06";
	    die "not ok 1\n$@\n" if ($@);
        }
} # End BEGIN
print "ok 1\n";

END {print "not ok 2\n" unless $loaded;}
use ControlX10::CM17 qw( send_cm17 0.05 );
$loaded = 1;
print "ok 2\n";

######################### End of black magic.

use strict;
my $tc = 5;	# next test number after setup

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    else {
        printf ("not ok %d\n",$tc++);
    }
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

###############################################################

my $serial_port; 

if ($OS_win) {
    $port = shift @ARGV || "COM1";
    $serial_port = Win32::SerialPort->new ($port,1);
}
else {
    $port = shift @ARGV || "/dev/ttyS0";
    $serial_port = Device::SerialPort->new ($port,1);
}
die "not ok 3\nCan't open serial port $port: $^E\n" unless ($serial_port);
print "ok 3\n";

$serial_port->databits(8);
$serial_port->baudrate(4800);
$serial_port->parity("none");
$serial_port->stopbits(1);
$serial_port->dtr_active(1);
$serial_port->handshake("none");
$serial_port->write_settings || die "not ok 4\nCould not set up port\n";
print "ok 4\n";

# end of preliminaries.

$main::config_parms{debug} = "";
my ($tick, $tock, $err);

is_zero($ControlX10::CM17::DEBUG);			# 5
is_ok(send_cm17($serial_port, 'A1J'));			# 6
is_zero($ControlX10::CM17::DEBUG);			# 7

$main::config_parms{debug} = "X10";
is_ok(send_cm17($serial_port, 'A9J'));			# 8
is_ok($ControlX10::CM17::DEBUG);			# 9

$main::config_parms{debug} = "";
is_ok(send_cm17($serial_port, 'AGJ'));			# 10
is_zero($ControlX10::CM17::DEBUG);			# 11

is_bad(send_cm17($serial_port, 'A2B'));			# 12
is_bad(send_cm17($serial_port, 'AHJ'));			# 13
is_bad(send_cm17($serial_port, 'Q1J'));			# 14
is_ok(ControlX10::CM17::send($serial_port, 'A1K'));	# 15
sleep 1;
is_ok(send_cm17($serial_port, 'A2J'));			# 16
is_ok(send_cm17($serial_port, 'AM'));			# 17
is_ok(send_cm17($serial_port, 'AL'));			# 18

$tick=$serial_port->get_tick_count;
is_ok(send_cm17($serial_port, 'A1K'));			# 19
$tock=$serial_port->get_tick_count;

$err=$tock - $tick;
is_bad (($err < 600) or ($err > 3000));			# 20
print "<1500> elapsed time=$err\n";

is_ok(send_cm17($serial_port, 'AN'));			# 21
is_ok(send_cm17($serial_port, 'AO'));			# 22
is_ok(send_cm17($serial_port, 'AP'));			# 23

$serial_port->close || die "\nclose problem with $port\n";
undef $serial_port;
