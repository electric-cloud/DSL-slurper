#############################################################################
#
# Copyright 2015 Electric-Cloud Inc.
#
#############################################################################
use strict;
use English;
use File::stat 'stat';
use Fcntl ':mode';

use ElectricCommander;
$| = 1;

# Check for the OS Type
my $osIsWindows = $^O =~ /MSWin/;

#############################################################################
#
# Global variables
#
#############################################################################
my $DEBUG=0;
my $server="ec601";
my $user="admin";
my $password="changeme";
my $dslDirectory="DSL";
my $timestamp="1";      # a long time ago

# Create a single instance of the Perl access to ElectricCommander
my $ec = new ElectricCommander({server=>$server, format => "json"});

#############################################################################
# login
#   initiate a login session with commander server
# Args:
#     None
#############################################################################
sub login(){
  $ec->login($user, $password);
}

#############################################################################
# processDirectory
#   parse all files and directories inside the current directory
# Args:
#     directory name
#     level
#############################################################################
sub processDirectory ($$) {
  my ($dir, $level)=$@;

  opendir(my $dh, $dir) || {
    printf("Cannot open $dir: $!");
    return 1;
  }

  while (my $filename=readdir ($dh)) {
    next if $filename =~ /^\./;   # skip ., .. and hidden files
    # get file information
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
    $atime, $mtime, $ctime, $blksize, $blocks) = stat($filename);

    if (S_ISDIR($mode)) {
      printf("%s+ %s\n", " "x $level, $filename);
      processDirectory("$dir/$filename", $level+1);
    }
    next if ($mtime <= $timestamp);
    # invoke DSL only on .groovy files
    if ($filename =~ /.groovy$/) {
      printf("%s%s\n", " "x $level, $filename);

      $ec->evalDsl({dslFile=>"$dir/$filename"})
    }
  }
}



#############################################################################
#
# Main
#
#############################################################################
login();
while(1) {
  processDirectory("$dslDirectory");
  $timestamp=localtime();
  sleep(5);
}
