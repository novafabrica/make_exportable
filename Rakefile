begin
  # Rspec 1.3.0
  require 'spec/rake/spectask'
  desc 'Default: run specs'
  task :default => :spec
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList["spec/**/*_spec.rb"]
  end

  Spec::Rake::SpecTask.new('rcov') do |t|
    t.spec_files = FileList["spec/**/*_spec.rb"]
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec']
  end
  
rescue LoadError
  # Rspec 2.0
  require 'rspec/core/rake_task'

  desc 'Default: run specs'
  task :default => :spec  
  Rspec::Core::RakeTask.new do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
  
  Rspec::Core::RakeTask.new('rcov') do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec']
  end

rescue LoadError
  puts "Rspec not available. Install it with: gem install rspec"  
end

namespace 'rails2.3' do
  task :spec do
    gemfile = File.join(File.dirname(__FILE__), 'lib', 'acts_as_taggable_on', 'compatibility', 'Gemfile')
    ENV['BUNDLE_GEMFILE'] = gemfile
    Rake::Task['spec'].invoke    
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "make_exportable"
    gemspec.summary = "Export your model's data effortless"
    gemspec.description = "MakeExportable is a Rails Gem/Plugin that makes exporting your model's data effortless. It works in a variety of formats and can filter down what gets exported using ActiveRecord's find method."
    gemspec.email = "matt@novafabirca.com"
    gemspec.homepage = "http://github.com/Fotoverite/make-exportable"
    gemspec.authors = ["Kevin Skoglund", "Matthew Bergman"]
    gemspec.files =  FileList["[A-Z]*", "{generators,lib,spec,rails}/**/*"] - FileList["**/*.log"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end