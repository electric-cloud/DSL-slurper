runProcedure(
  projectName: '/plugins/ECSCM-Perforce/project',
  procedureName: 'CreateConfiguration',
  credential: [
    credentialName: "credential",
    userName: "foo",
    password: "bar"
  ],
  actualParameter: [
    config: "lego",
    debug: "1",
    desc: "Perforce configuration",
    P4CHARSET: "uft8",
    P4COMMANDCHARSET: "noidea",
    P4HOST: "p4host",
    P4PORT: "p4server:1234",
    P4TICKETS: "/tmp/ticket.txt",
    credential: "credential",
  ]
)
