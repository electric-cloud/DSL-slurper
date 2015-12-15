############################################################################
#
# Copyright 2015 Electric-Cloud Inc.
#
#############################################################################
use strict;
use English;
use ElectricCommander;
use LWP::Simple 'get';
$| = 1;

# Create a single instance of the Perl access to ElectricCommander
my $ec = new ElectricCommander();

#############################################################################
#
# Invoke a API call
#
#############################################################################
sub InvokeCommander {

    my $optionFlags = shift;
    my $commanderFunction = shift;
    my $xPath;
    my $success = 1;

    my $bSuppressLog = $optionFlags =~ /SuppressLog/i;
    my $bSuppressResult = $bSuppressLog || $optionFlags =~ /SuppressResult/i;
    my $bIgnoreError = $optionFlags =~ /IgnoreError/i;

    # Run the command
    # print "Request to Commander: $commanderFunction\n" unless ($bSuppressLog);

    $ec->abortOnError(0) if $bIgnoreError;
    $xPath = $ec->$commanderFunction(@_);
    $ec->abortOnError(1) if $bIgnoreError;

    # Check for error return
    my $errMsg = $ec->checkAllErrors($xPath);
    my $errCode=$xPath->findvalue('//code',)->value();
    if ($errMsg ne "") {
        $success = 0;
    }
    if ($xPath) {
        print "Return data from Commander:\n" .
               $xPath->findnodes_as_string("/") . "\n"
            unless $bSuppressResult;
    }

    # Return the result
    return ($success, $xPath, $errMsg, $errCode);
}

sub installPlugin {
  my $name=shift;

  my $tmpDir='/tmp';
  unlink("$tmpDir/$name");

  # Download file from GitHub
  my $url = "http://github.com/electric-cloud/$name/blob/master/$name.jar?raw=true";
  my $file= get $url;
  open F, "> $tmpDir/$name.jar" or die "$! $name.jar";
  binmode F;
  print F $file;
  close F;

  # installPlugin
  my ($ok, $xml, $errMsg, $errCode) =
       InvokeCommander("SuppressLog", 'installPlugin', "$tmpDir/$name.jar");
  my $pName=$xml->findnodes('//plugin/pluginName')->string_value();
  printf("Plugin $pName installed\n");

  # promotePlugin
  ($ok, $xml, $errMsg, $errCode) =
       InvokeCommander("SuppressLog", 'promotePlugin', $pName);
  printf("Plugin $pName promoted\n");
}

installPlugin("EC-Admin");
installPlugin("EC-Zendesk");
installPlugin("EC-ShareFile");
installPlugin("EC-Support");
