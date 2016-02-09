project("Default") {
  application("userPortal") {
    applicationTier("AppServer") {
      component("Portal") {
        description = "Portal component for the DSL demo."
        pluginKey = "EC-Artifact"

        ec_content_details.with {
            artifactName = 'com.ec:userportal'
            artifactVersionLocationProperty = '/myJob/retrievedArtifactVersions/$[assignedResourceName]'
            overwrite = 'update'
            filterList = ''
            pluginProcedure = 'Retrieve'
            pluginProjectName = 'EC-Artifact'
            retrieveToDirectory = '/tmp'
            versionRange = '$[version]'
        }

        process("Install") {
          description = "Deploy the Portal component"
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

          processStep("Deploy") {
            description = "Deploy the war file to Jboss container"
            processStepType = "plugin"
            errorHandling = "failProcedure"
            applicationName = null      // to force a component process vs app process
            applicationTierName = null

            subprocedure = 'DeployApp'
            subproject = '/plugins/EC-JBoss/project'

            actualParameter("appname", 'UP/userportal.war')
            actualParameter("assignallservergroups", '0')
            actualParameter("assignservergroups", '')
            actualParameter("force", '1')
            actualParameter("runtimename", 'UP/userportal.war')
            actualParameter("scriptphysicalpath", '/opt/wildfly/bin/jboss-cli.sh')
            actualParameter("serverconfig", 'wildfly')
            actualParameter("warphysicalpath", '/tmp/userportal.war')
          }   // component process step Deploy

          // create transition
          processDependency("Retrieve", "Deploy")
        }     // component process Install
      }       // component
    }
  }
}
