["DEV", "QA"].each { _env ->

  environment (_env) {
    projectName = "Default"
    environmentTier("JBoss") {
      resource("jboss_" + _env){}
    }

    environmentTier("MySQL") {
      resource("mysql_" + _env){}
    }
  }
}
