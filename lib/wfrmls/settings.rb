
CONFIG_FILE_NAME ||= File.expand_path('~/wfrmls_config.yml')

require 'configliere'

Settings.use :define, :commandline, :commands

Settings.define_command :comp,      description: "Find comparisons for ADDRESS."
Settings.define_command :overview,  description: "Show overview for ADDRESS."
Settings.define_command :details,   description: "Show details for ADDRESS."
Settings.define_command :reo,       description: "Find bank owned properties."

Settings.define :output, description: "Store details in FILE.",
  flag: :o, default: "last.yml"
Settings.define :input, description: "Use details from FILE.",
  flag: :i, default: "last.yml"

Settings.define :status, description: "Sale status.",
  type: Array, default: ['Active', 'Sold', 'Under Contract', 'Expired']
Settings.define :days_back, description: "Compare NUMBER of days back.",
  type: Integer, default: 120
Settings.define :county, description: "Select county.",
  type: Array, default: ['Davis']
Settings.define :owner, description: "Use OWNER to help find property."

Settings.read CONFIG_FILE_NAME

Settings.resolve!
