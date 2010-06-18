$LOAD_PATH << "." unless $LOAD_PATH.include?(".")

begin
  require "rubygems"
  require "bundler"
  require "active_record"
  require "fastercsv" unless ActiveRecord::VERSION::MAJOR >= 3



  if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.5")
    raise RuntimeError, "Your bundler version is too old." +
      "Run `gem install bundler` to upgrade."
  end

  # Set up load paths for all bundled gems
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run `bundle install`?"
end

Bundler.require(:default, :test)

require File.expand_path('../../lib/make_exportable', __FILE__)
Date::DATE_FORMATS[:default] = '%d/%m/%Y'
Time::DATE_FORMATS[:default] = '%A %B %d %Y at %I:%M%p'

ENV['DB'] ||= 'sqlite3'

database_yml = File.expand_path('../database.yml', __FILE__)
if File.exists?(database_yml)
  active_record_configuration = YAML.load_file(database_yml)[ENV['DB']]

  ActiveRecord::Base.establish_connection(active_record_configuration)
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))

  ActiveRecord::Base.silence do
    ActiveRecord::Migration.verbose = false

    load(File.dirname(__FILE__) + '/schema.rb')
    load(File.dirname(__FILE__) + '/models.rb')
  end

else
  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

def clean_database!
  models = [User, Post]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
    ActiveRecord::Base.connection.execute "delete from sqlite_sequence where name='#{model.table_name}'" 
  end
end
