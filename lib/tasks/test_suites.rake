#
# Organize RSpec tests in suites w/ retry. Requires rspec-core 2.11.0.
#
# (c) 2012 Daniel Doubrovkine, Art.sy
# MIT License
#
 
require 'rspec/core/rake_task'
APP_ROOT = File.expand_path("../../../", __FILE__)
SPEC_SUITES = [
  # { :id => :initializers, :title => 'initializers', :pattern => "spec/initializers/**/*_spec.rb" },
  { :id => :models, :title => 'model tests', :pattern => "spec/models/**/*_spec.rb" },
  # { :id => :acceptance, :title => 'acceptance tests', :pattern => "spec/acceptance/**/*_spec.rb" },
  { :id => :controllers, :title => 'controller tests', :pattern => "spec/controllers/**/*_spec.rb" },
  { :id => :views, :title => 'view tests', :pattern => "spec/views/**/*_spec.rb" }
  # { :id => :mailers, :title => 'mailer tests', :pattern => "spec/mailers/*_spec.rb" },
]
 
namespace :spec do
  namespace :suite do
    SPEC_SUITES.each do |suite|
      desc "Run all specs in #{suite[:title]} spec suite"
      task "#{suite[:id]}" do
        rspec_failures = File.join(APP_ROOT, 'rspec.failures')
        FileUtils.rm_f rspec_failures
        Rake::Task["spec:suite:#{suite[:id]}:run"].execute
        unless $?.success?
          puts "[#{Time.now}] Failed, retrying #{File.read(rspec_failures).split(/\n+/).count} failure(s) in spec:suite:#{suite[:id]} ..."
          Rake::Task["spec:suite:#{suite[:id]}:retry"].execute
        end
      end
      RSpec::Core::RakeTask.new("#{suite[:id]}:run") do |t|
        t.pattern = suite[:pattern]
        t.verbose = false
        t.fail_on_error = false
        t.rspec_opts = [
          "--require", "#{APP_ROOT}/spec/support/formatters/failures_formatter.rb",
          "--format", "RSpec::Core::Formatters::FailuresFormatter",
          File.read(File.join(APP_ROOT, ".rspec")).split(/\n+/).map { |l| l.shellsplit }
        ].flatten
      end
      RSpec::Core::RakeTask.new("#{suite[:id]}:retry") do |t|
        t.pattern = suite[:pattern]
        t.verbose = false
        t.fail_on_error = false
        t.rspec_opts = [
          "-O", File.join(APP_ROOT, 'rspec.failures'),
          File.read(File.join(APP_ROOT, '.rspec')).split(/\n+/).map { |l| l.shellsplit }
        ].flatten
      end
    end
    desc "Run all spec suites"
    task :all => :environment do
      failed_suites = []
      SPEC_SUITES..each do |suite|
        puts "Running spec:suite:#{suite[:id]} ..."
        Rake::Task["spec:suite:#{suite[:id]}"].execute
        failed_suites << suite unless $?.success?
      end
      raise "Spec suite failed" unless failed_suites.empty?
    end
  end
end