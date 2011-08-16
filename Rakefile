require "rubygems"
require "bundler/setup"

PROJECT_ROOT = File.expand_path("..", __FILE__)
$:.unshift "#{PROJECT_ROOT}/lib"

require "heroku/version"
require "rspec/core/rake_task"

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = true
end

task :default => :spec

def builder(action, ext)
  package_file = "pkg/heroku-#{Heroku::VERSION}.#{ext}"
  puts "#{action}: #{package_file}"
  system %{ ruby build/#{ext}/#{action} "#{PROJECT_ROOT}" "#{package_file}" }
end

namespace :package do
  desc "package the exe version"
  task :exe do
    if RUBY_PLATFORM =~ /mingw32/
      builder :package, :exe
    end
  end

  desc "package the gem version"
  task :gem do
    builder :package, :gem
  end

  desc "package the tgz version"
  task :tgz do
    builder :package, :tgz
  end
end

desc "package all"
task :package => %w( package:gem package:tgz )

namespace :release do
  desc "release the exe version"
  task :exe => "package:exe" do
    if RUBY_PLATFORM =~ /mingw32/
      builder :release, :exe
    end
  end

  desc "release the gem version"
  task :gem => "package:gem" do
    builder :release, :gem
  end

  desc "release the tgz version"
  task :tgz => "package:tgz" do
    builder :release, :tgz
  end
end

desc "release all"
task :release => %w( release:gem release:tgz )
