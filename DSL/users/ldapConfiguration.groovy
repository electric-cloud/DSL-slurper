import groovy.json.*

// Delete and Create new Log file
"rm -f /tmp/debug.log".execute()
def logFile= new File('/tmp/debug.log')

logFile << "Start\n";
def resp=testDirectoryProvider(userName: "lrochette")

logFile << "Result: " + resp.userAuthenticationResult.outcome.toString() + "\n"

//logFile << "\nProcedures\n"
//resp=getProject(projectName: "slurper")
//logFile << "Dump: " + resp.dump() + "\n"
//logFile << "Default: " + new JsonBuilder(resp).toPrettyString()+ "\n"

logFile << "End\n";
