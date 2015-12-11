logFile = new File("/tmp/dsl.log")
resp=getProperty(propertyName:"bar", systemObjectName: "server")
logFile << resp.toString()
if (! resp) {
  property(propertyName:"bar", systemObjectName: "server",value: 1)
}

/*
property("foo") {
  value = "bar3"
  systemObjectName = "server"
}
*/
// comment
