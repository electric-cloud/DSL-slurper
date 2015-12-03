<h1>DSL-slurper</h1>

<p>DSL-slurper is a Perl or powershell script that check continuously for any change in a DSL directory structure and invoke ectool evalDsl</p>

<p>The original idea was from <a href="https://www.linkedin.com/in/michaelerhardsen">Michael Erhardsen</a>. I simply borrowed it with his permission and ported his Windows powershell version to Linux.</p>

<h2>Configuration</2>
<p>In the dsl-slurper, set your server name, DSL top directory, login and password.</p>

<p>run it with ec-perl dsl-slurper. It will run on forever loop and simply evaluate the files that have been modified since the previous loop.</p>
