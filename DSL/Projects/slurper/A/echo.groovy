project("slurper") {
  procedure("A") {
    step ("echo") {
      projectName = "slurper"
      procedureName = "A"
      shell="ec-perl"
      command = '''printf('Hello World');'''
    }
  }
}
