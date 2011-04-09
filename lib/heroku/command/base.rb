require "fileutils"
require "heroku/auth"
require "heroku/command"

class Heroku::Command::Base
  include Heroku::Helpers

  def self.namespace
    self.to_s.split("::").last.downcase
  end

  attr_reader :args
  attr_reader :options

  def initialize(args=[], options={})
    @args = args
    @options = options
  end

  def heroku
    Heroku::Auth.client
  end

protected

  def self.inherited(klass)
    return if klass == Heroku::Command::BaseWithApp
    Heroku::Command.register_namespace(
      :name => klass.namespace,
      :description => nil
    )
  end

  def self.method_added(method)
    return if self == Heroku::Command::Base
    return if self == Heroku::Command::BaseWithApp
    return if private_method_defined?(method)
    return if protected_method_defined?(method)

    help = extract_help(*(caller.first.split(":")[0..1]))

    resolved_method = (method.to_s == "index") ? nil : method.to_s

    command     = [ self.namespace, resolved_method ].compact.join(":")

    Heroku::Command.register_command(
      :klass       => self,
      :method      => method,
      :namespace   => self.namespace,
      :command     => command,
      :banner      => extract_banner(help) || command,
      :help        => help,
      :summary     => extract_summary(help),
      :description => extract_description(help),
      :options     => extract_options(help)
    )
  end

  def self.extract_help(file, line)
    buffer = []
    lines  = File.read(file).split("\n")

    catch(:done) do
      (line.to_i-2).downto(1) do |i|
        case lines[i].strip[0..0]
          when "", "#" then buffer << lines[i]
          else throw(:done)
        end
      end
    end

    buffer.map! do |line|
      line.strip.gsub(/^#/, "")
    end

    buffer.reverse.join("\n").strip
  end

  def self.extract_banner(help)
    help.split("\n").first
  end

  def self.extract_summary(help)
    extract_description(help).split("\n").first
  end

  def self.extract_description(help)
    lines = help.split("\n").map(&:strip)
    lines.shift
    lines.reject do |line|
      line =~ /^-(.+)#(.+)/
    end.join("\n").strip
  end

  def self.extract_options(help)
    help.split("\n").map(&:strip).select do |line|
      line =~ /^-(.+)#(.+)/
    end.inject({}) do |hash, line|
      description = line.split("#", 2).last.strip
      long  = line.match(/--([A-Za-z ]+)/)[1].strip
      short = line.match(/-([A-Za-z ])/)[1].strip
      hash.update(long.split(" ").first => { :desc => description, :short => short, :long => long })
    end
  end

  def extract_option(name, default=true)
    key = name.gsub("--", "").to_sym
    return unless options[key]
    value = options[key] || default
    # puts "NAME:#{name}"
    # puts "VALUE:#{value}"
    block_given? ? yield(value) : value
  end

  def extract_app
    if options[:app].is_a?(String)
      options[:app]
    elsif app_from_dir = extract_app_in_dir(Dir.pwd)
      app_from_dir
    else
      raise Heroku::Command::CommandFailed, "No app specified.\nRun this command from an app folder or specify which app to use with --app <app name>"
    end
  end

  def extract_app_in_dir(dir)
    return unless remotes = git_remotes(dir)

    if remote = options[:remote]
      remotes[remote]
    elsif remote = extract_app_from_git_config
      remotes[remote]
    else
      apps = remotes.values.uniq
      return apps.first if apps.size == 1
    end
  end

  def extract_app_from_git_config
    remote = git("config heroku.remote")
    remote == "" ? nil : remote
  end

  def git_remotes(base_dir=Dir.pwd)
    remotes = {}
    original_dir = Dir.pwd
    Dir.chdir(base_dir)

    git("remote -v").split("\n").each do |remote|
      name, url, method = remote.split(/\s/)
      if url =~ /^git@#{heroku.host}:([\w\d-]+)\.git$/
        remotes[name] = $1
      end
    end

    Dir.chdir(original_dir)
    remotes
  end

  def escape(value)
    heroku.escape(value)
  end
end

class Heroku::Command::BaseWithApp < Heroku::Command::Base
  def initialize(args=[], options={})
    super
  end

  def app
    extract_app
  end
end
