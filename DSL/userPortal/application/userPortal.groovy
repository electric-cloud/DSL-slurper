application("userPortal") {
  projectName = "Default"
  description = "Application model for john Doe's User Portal website"


  // Application process
  process("Deploy") {
    applicationName = "userPortal"

    formalParameter ("version") {
      description = "The version of the war file to install"
      label = "Version"
      defaultValue = "1.0.0"
      required = "1"
    }

    processStep("Portal") {
      description = "Deploy the Portal component"
      processStepType = "process"
      applicationName = "userPortal"
      errorHandling = "failProcedure"
      subcomponent = "Portal"
      subcomponentProcess = "Install"
      applicationTierName = "AppServer"
    }

    processStep("Schema") {
      description = "Deploy the Schema component"
      processStepType = "process"
      applicationName = "userPortal"
      errorHandling = "failProcedure"
      subcomponent = "Schema"
      subcomponentProcess = "Execute"
      applicationTierName = "Database"
    }

  }       // Enfo Application process
}
