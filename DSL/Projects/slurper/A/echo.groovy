project("slurper") {
  procedure("A") {
    step ("echo") {
      shell="ec-perl"
      command = '''printf('Hello World');'''
      description = "This is my step by Wesley"
    }
  }
}
