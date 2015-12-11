#############################################################################
#
# Copyright 2015 Electric-Cloud Inc.
#
#############################################################################
use strict;
use English;
use ElectricCommander;
use Data::Dumper;
$| = 1;

# Create a single instance of the Perl access to ElectricCommander
my $ec = new ElectricCommander({'format' => "json"});

##
## Check existence of configuration
my $config="lego7";
my $prop=getP("/plugins/ECSCM/project/scm_cfgs/$config/scmPlugin");
if ($prop) {
   printf("Configuration already exists!\n");
   exit(1);
}

my $json=$ec->runProcedure(
  {
    projectName => '/plugins/ECSCM-Perforce/project',
    procedureName => 'CreateConfiguration',
    actualParameter => [
      {actualParameterName => "config", value => $config},
      {actualParameterName => "debug", value => "1"},
      {actualParameterName => "desc", value => "Perforce configuration"},
      {actualParameterName => "P4CHARSET", value => "uft8"},
      {actualParameterName => "P4COMMANDCHARSET", value => "noidea"},
      {actualParameterName => "P4HOST", value => "p4host"},
      {actualParameterName => "P4PORT", value => "p4server:1234"},
      {actualParameterName => "P4TICKETS", value => "/tmp/ticket.txt"},
      {actualParameterName => "credential", value => "credential"}
    ],
    credential      => [
     {
      credentialName => 'credential',
      userName => "abc",
      password => "abc"
     }
    ]
  }
);

# Wait for job to finish
my $jobId=$json->{responses}->[0]->{jobId};
$ec->waitForJob($jobId, "30", "completed");

my $jobData  = $ec->getJobDetails($jobId);
my $outcome = $jobData->{responses}->[0]->{job}->{outcome}; ## success or error
if ($outcome ne "success") {
  printf("Ccofiguration creation failed!\n");
  exit(1);

}
#############################################################################
#
# Return property value or undef in case of error (non existing)
#
#############################################################################
sub getP
{
  my $prop=shift;
  my $expand=shift;

  my($success, $xPath, $errMsg, $errCode)= InvokeCommander("SuppressLog IgnoreError", "getProperty", $prop);

  return undef if ($success != 1);
  my $val= $xPath->findvalue("//value");
  return($val);
}

#############################################################################
#
# Invoke a API call
#
#############################################################################
sub InvokeCommander {

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
