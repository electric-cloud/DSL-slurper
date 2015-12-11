project("Default") {
  application("userPortal") {
    applicationTier("Database") {
      component("Schema") {
        description = "Portal component"
        pluginKey = "EC-Artifact"

        ec_content_details.with {
            artifactName = 'com.ec:userportal_schema'
            artifactVersionLocationProperty = '/myJob/retrievedArtifactVersions/$[assignedResourceName]'
            overwrite = 'update'
            filterList = ''
            pluginProcedure = 'Retrieve'
            pluginProjectName = 'EC-Artifact'
            retrieveToDirectory = '/tmp'
            versionRange = '1.0.0'
        }

        process("Execute") {
          description = "Execute Database configuration"
          processType = "DEPLOY"
          applicationName = null      // to force a component process vs app process
          componentApplicationName = "userProject"

          // Step to Retrieve artifact version
          processStep("Retrieve") {
            description = "Retrieve the war file"
  					processStepType = "component"
            errorHandling = "failProcedure"
            applicationName = null
            applicationTierName = null

  					subprocedure = "Retrieve"
  					subproject = "/plugins/EC-Artifact/project"

  					actualParameter("artifactName", '$[/myComponent/ec_content_details/artifactName]')
  					actualParameter("artifactVersionLocationProperty", '$[/myComponent/ec_content_details/artifactVersionLocationProperty]')
  					actualParameter("filterList", '$[/myComponent/ec_content_details/filterList]')
  					actualParameter("overwrite", '$[/myComponent/ec_content_details/overwrite]')
  					actualParameter("versionRange", '$[/myJob/ec_Portal-version]')
          }   // component process step Retrieve

          processStep("sqlCommand") {
            description = "Execute SQL command"
            processStepType = "plugin"
            errorHandling = "failProcedure"
            applicationName = null      // to force a component process vs app process
            applicationTierName = null

            subprocedure = 'ExecuteSQL'
            subproject = '/plugins/EC-MYSQL/project'

            actualParameter("ConfigName", 'mysql')
            actualParameter("CommandLineUtility", 'mysql')
            actualParameter("DBName", 'DB')
            actualParameter("Server", 'localhost')
            actualParameter("Port", '3306')
            actualParameter("SQLFilePath", '/tmp/schema.sql')
          }   // component process step Deploy

          // create transition
          processDependency("Retrieve", "sqlCommand")

        }       // end of component process "Execute"
      }
    }
  }
}
