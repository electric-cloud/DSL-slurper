project("slurper") {
  procedure("A") {
    formalParameter("port") {
      defaultValue="8125"
      required=1
    }
    formalParameter("statsd") {
      defaultValue="statsd"
      required=1;
    }
    step("generateStatsdMetric") {
      shell="ec-perl"
      command ='''
for (my $i=0; $i<100 ; $i++) {
  my $rand=int(rand()*10+1);
  printf("$rand\n");
  system("echo \'flow.ec601.DSL.eval:$rand|c\' |nc -w 1 -u $[statsd] $[port]");
  # Error check
  if (rand() < .30) {
    # cannot report more error than eval
    $error= int(rand()*5+1);
    $error=($error>$rand)?$rand:$error;
    printf("    ERROR: $error\n");
    system("echo \'flow.ec601.DSL.error:$error|c\' |nc -w 1 -u $[statsd] $[port]");
  } else {
    system("echo \'flow.ec601.DSL.error:0|c\' |nc -w 1 -u $[statsd] $[port]");
  }
  sleep(10);  # 1 set of date per statsd flush
}
      '''
    }
  }
}
