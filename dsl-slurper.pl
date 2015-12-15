#!/usr/bin/env ec-perl
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
# Dec 07, 2015  lrochette   Only run processDirectory when new files are
#                           detected
# Dec 08, 2015  lrochette   Pass parameters to evalDsl
#############################################################################
use strict;
use English;
use Fcntl ':mode';
use ElectricCommander;
use Data::Dumper;
use Getopt::Long 'GetOptions';
use File::Find;
use Term::ANSIColor;

$| = 1;             # Force flush

# Check for the OS Type
my $osIsWindows = $^O =~ /MSWin/;

#############################################################################
#
# Global variables
#
#############################################################################
my $version = "0.3";
my $tsFile = ".dsl";          # filename where the timestamp is saved
my $DEBUG=1;
my $server="ec601";           # Default server name
my $user="admin";             # default user name
my $password="changeme";      # Default password
my $dslDirectory=".";         # Default directory where to pick up code
my $parameters="";            # parameter List
my $dslParams="";             # parameter string (JSON) for evalDsl
my $timestamp="1";            # a long time ago (Default timestamp)
my $force="0";                # To force all files parsing
my $ntest="../ec-testing/ntest";  # Testing mode
my $error=0;                  # was there any error in my eval loop
#
# color Definitions
my $plusColor='blue';
my $errorColor='red';
my $okColor='green';

# To force some ordering in the parsing of the structure
my @orderedList=qw(groups users projects);

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

  my $indent=" +" x $level;
  printf ("%s %s\n", colored($indent,$plusColor), $dir);
#  printf ("%s %s\n", "  " x $level, colored("+",'blue') x $level, $dir);
  opendir(my $dh, $dir) or die("Cannot open $dir: $!");
  my @content=readdir $dh;
  my @directories=();
  my @before=();
  my @after=();

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
      printf("  %s %s", "  "x $level, $filename);

      my %options=();
      $options{dslFile}="$dir/$filename";
      $options{parameters}=$dslParams if ($dslParams);

      my ($ok, $json, $errMsg, $errCode)=invokeCommander(
        "SuppressLog IgnoreError",'evalDsl', \%options);
      if ($ok) {
        printf (" (%s)\n", colored("OK", $okColor));
      } else {
        $error=1;
        printf("\n%s\n", colored($errMsg, $errorColor));
      }
    } elsif ($filename =~ /.groovy.pl$/) {
      # Workaround for stuff you cannot do in DSL yet
      printf("  %s %s\n", "  "x $level, $filename);
      system("ec-perl $dir/$filename");
    }
  }
  closedir $dh;
}

#############################################################################
# parseParameters
#   parse all the parameters passed to the script and rewrite them in an
#       evalDsl format
# Args:
#     None
#############################################################################
sub parseParameters {
    my @pairs=split(',', $parameters);

    $dslParams="{";
    my $index=0;
    foreach my $pair (@pairs) {
      my ($name,$value)=split("=", $pair);
      $dslParams .= "," if ($index);   # Add comma to separate elements
      $dslParams .= sprintf("\"%s\":\"%s\"", $name, $value);
      $index++;
    }
    $dslParams .= "}";
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
 --directory DIR        directory to monitor and parse
 --test      PATH       path to ntest
 --force                ignore timestamp and re-eval DSL
 --parameters PARAMS    parameters to pass on evalDsl as p1=v1,p2=v2,...
 --help                 This page

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
  'server=s'     => \$server,
  'user=s'       => \$user,
  'password=s'   => \$password,
  'directory=s'  => \$dslDirectory,
  'parameters=s' => \$parameters,
  'test=s'       => \$ntest,
  'force'        => \$force,
  'help'         => \&usage) || usage();

login();

# Reset existing timestamp if  in FORCE mode
if ($force || ! -f "$dslDirectory/$tsFile") {
  open(my $fh, "> $dslDirectory/$tsFile")
    || print("Warning: cannot save timestamp in $dslDirectory/$tsFile!\n$!\n");
  print $fh "1";
  close($fh);
  utime  1,1, "$dslDirectory/$tsFile"
}

# Read timestamp
$timestamp=`cat "$dslDirectory/$tsFile"`;

# Any parameters?
parseParameters() if ($parameters);


printf("Slurping DSL and Perl from $dslDirectory:\n");

while(1) {
  my @newFiles=`find $dslDirectory -type f -newer $dslDirectory/$tsFile`;
  #print(@newFiles) if ($DEBUG);

  if (@newFiles) {
    $error=0;
    # found new files
    # save previous timestamp (so files created during process will be eval'ed next round)
    my $newTimestamp=time();
    processDirectory($dslDirectory, 0);

    # Write old timestamp just after the find
    # so next roud, files modified during the process will be found
    open(my $fh, "> $dslDirectory/$tsFile")
      || print("Warning: cannot save the timestamp in $dslDirectory/$tsFile!\n$!\n");
    print $fh $newTimestamp;
    # set time used for processDirectory
    $timestamp=$newTimestamp;
    close($fh);

    if (-d "$dslDirectory/test" && -f $ntest) {
      if ($error) {
        printf("Skipping automatic testing due to an error\n");
      } else {
        printf("Automatic testing: $ntest\n");
        system("$ntest --target=$server $dslDirectory/test");
      }
    }
    printf("\n\n");
  }
  else {
    # print (".") if ($DEBUG);
  }
  sleep(2);
}
