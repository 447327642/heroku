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

def builder(action, type, ext=type)
  package_file = "pkg/heroku-#{Heroku::VERSION}.#{ext}"
  puts "#{action}: #{package_file}"
  system %{ ruby build/#{type}/#{action} "#{PROJECT_ROOT}" "#{package_file}" }
end

namespace :package do
  desc "package the deb version"
  task :deb do
    if RUBY_PLATFORM =~ /linux/
      builder :package, :deb, "apt.tgz"
    end
  end

  desc "package the pkg version"
  task :pkg do
    if RUBY_PLATFORM =~ /darwin/
      builder :package, :pkg
    end
  end

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


namespace :release do
  desc "release the deb version"
  task :deb => "package:deb" do
    builder :release, :deb, "apt.tgz"
  end

  desc "release the deb version"
  task :pkg => "package:pkg" do
    builder :release, :pkg
  end

  desc "release the exe version"
  task :exe => "package:exe" do
    builder :release, :exe
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


namespace :build do
  desc "run osx release tasks"
  task :osx => %w( release:gem release:tgz release:pkg )

  desc "run windows release tasks"
  task :windows => "release:exe"

  desc "run debian release tasks"
  task :debian => "release:deb"
end
