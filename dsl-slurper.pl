#############################################################################
#
# Copyright 2015 Electric-Cloud Inc.
#
# Author: L. Rochette (lrochette@electric-cloud.com)
#
# Changelog
#
# Date          Who         Comment
# ---------------------------------------------------------------------------
# Dec 03, 2015  lrochette   Initial version
#############################################################################
use strict;
use English;
use Fcntl ':mode';
use ElectricCommander;
use Data::Dumper;
use Getopt::Long 'GetOptions';

$| = 1;             # Force flush

# Check for the OS Type
my $osIsWindows = $^O =~ /MSWin/;

#############################################################################
#
# Global variables
#
#############################################################################
my $version = "0.1";

my $DEBUG=1;
my $server="ec601";
my $user="admin";
my $password="changeme";
my $dslDirectory="DSL";
my $timestamp="1";      # a long time ago

# Create a single instance of the Perl access to ElectricCommander
my $ec = new ElectricCommander({server=>$server, format => "json"});

#############################################################################
# invokeCommander
#    Invoke any API call
# Args:
#   optionFlags: SuppressLog, SuppressResult and/or IgnoreError as a string
#   function:    API call to make
#   parameters: in the same form than a normal API call
#
# Return:
#   success: 1 for success, 0 for error
#   result:  the JSON block returned by the API
#   errMsg: full error message
#   errCode: error code
#############################################################################
sub invokeCommander {

    my $optionFlags = shift;
    my $commanderFunction = shift;
    my $result;
    my $success = 1;
    my $errMsg;
    my $errCode;

    my $bSuppressLog = $optionFlags =~ /SuppressLog/i;
    my $bSuppressResult = $bSuppressLog || $optionFlags =~ /SuppressResult/i;
    my $bIgnoreError = $optionFlags =~ /IgnoreError/i;

    # Run the command
    # print "Request to Commander: $commanderFunction\n" unless ($bSuppressLog);

    $ec->abortOnError(0) if $bIgnoreError;
    $result = $ec->$commanderFunction(@_);
    $ec->abortOnError(1) if $bIgnoreError;

    # Check for error return
    if (defined ($result->{responses}->[0]->{error})) {
        $errCode=$result->{responses}->[0]->{error}->{code};
        $errMsg=$result->{responses}->[0]->{error}->{message};
    }

    if ($errMsg ne "") {
        $success = 0;
    }
    if ($result) {
        print "Return data from Commander:\n" .
               Dumper($result) . "\n"
            unless $bSuppressResult;
    }

    # Return the result
    return ($success, $result, $errMsg, $errCode);
}

#############################################################################
# login
#   initiate a login session with commander server
# Args:
#     None
#############################################################################
sub login {
  $ec->login($user, $password);
}

#############################################################################
# processDirectory
#   parse all files and directories inside the current directory
# Args:
#     directory name
#     level
#############################################################################
sub processDirectory {
  my ($dir, $level)=@_;

  printf("%s+ %s\n", "  " x $level, $dir);
  opendir(my $dh, $dir) or die("Cannot open $dir: $!");
  my @content=readdir $dh;

  foreach my $filename (@content) {
    next if $filename =~ /^\./;   # skip ., .. and hidden files
    # get file information
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
    $atime, $mtime, $ctime, $blksize, $blocks) = stat("$dir/$filename");
    if (S_ISDIR($mode)) {
      processDirectory("$dir/$filename", $level+1);
    }
    next if ($mtime <= $timestamp);

    # invoke DSL only on .groovy files
    if ($filename =~ /.groovy$/) {
      printf("  %s%s\n", "  "x $level, $filename);

      my ($ok, $json, $errMsg, $errCode)=invokeCommander(
        "SuppressLog IgnoreError",'evalDsl', {dslFile=>"$dir/$filename"});
      if (!$ok) {
        printf($errMsg);
      }
    }
  }
  closedir $dh;
}


#############################################################################
# Usage
#
#############################################################################
sub usage {
  printf("
Copyright 2015 Electric Cloud
dsl-slurper $version: import DSL changes into ElectricFlow

Options:
 --server    SERVER     ElectricFlow server
 --user      USER       username
 --password  PASSWORD   password
 --dslDirectory DIR     directory to monitor and parse
");
  exit(1);
}



#############################################################################
#
# Main
#
#############################################################################

#
# parse optionFlags
#
GetOptions(
  'server=s' => \$server,
  'user=s' =>\$user,
  'password=s' =>\$password,
  'dsl=s' => \$dslDirectory,
  'help' => \&usage) || usage();

login();
while(1) {
  processDirectory($dslDirectory);
  $timestamp=time();
  printf("\n\n");
  sleep(5);
}
