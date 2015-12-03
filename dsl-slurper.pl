#############################################################################
#
# Copyright 2015 Electric-Cloud Inc.
#
#############################################################################
use strict;
use English;
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
my $DEBUG=1;
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

      $ec->evalDsl({dslFile=>"$dir/$filename"})
    }
  }
  closedir $dh;
}



#############################################################################
#
# Main
#
#############################################################################
login();
while(1) {
  processDirectory($dslDirectory);
  $timestamp=time();
  printf("\n\n");
  sleep(5);
}
