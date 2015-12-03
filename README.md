#DSL-slurper

DSL-slurper is a Perl or powershell script that check continuously for any
change in a DSL directory structure and invoke ectool evalDsl

The original idea was from [Michael Erhardsen](https://www.linkedin.com/in/michaelerhardsen). I simply borrowed
it with his permission and ported his Windows powershell version to Linux.

##Configuration

In the dsl-slurper, set your server name, DSL top directory, login and password,
or you can use some options to overwrite the default value. See the ---help
option for details.

Run it with "ec-perl dsl-slurper.pl". It will run in a forever loop and simply
evaluate the files that have been modified since the previous loop.


##Authors
* Windows: [Michael Erhardsen](mailto:michael.erhardsen@LEGO.com)
* Linux: [Laurent Rochette](mailto:lrochette@electric-cloud.com)
