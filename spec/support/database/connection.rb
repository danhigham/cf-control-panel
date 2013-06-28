require 'sequel'
require 'logger'

db = Sequel.sqlite()
db.loggers << Logger.new($stdout)

Sequel.extension :migration
Sequel::Migrator.apply(db, './migrations/')
Sequel::Model.db = db
  
