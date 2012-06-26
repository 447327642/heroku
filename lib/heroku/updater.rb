require 'heroku/helpers'

module Heroku
  module Updater

    extend Heroku::Helpers

    def self.installed_client_path
      File.expand_path("../../..", __FILE__)
    end

    def self.updated_client_path
      File.join(home_directory, ".heroku", "client")
    end

    def self.latest_local_version
      maximum_version(client_version_from_path(installed_client_path), client_version_from_path(updated_client_path))
    end

    def self.client_version_from_path(path)
      version_file = File.join(path, "lib/heroku/version.rb")
      if File.exists?(version_file)
        File.read(version_file).match(/VERSION = "([^"]+)"/)[1]
      else
        '0.0.0'
      end
    end

    def self.disable(message=nil)
      @disable = message if message
      @disable
    end

    def self.check_disabled!
      error disable if disable
    end

    def self.update(url, autoupdate=false)
      require "fileutils"
      require "tmpdir"
      require "zip/zip"

      user_agent = Heroku::USER_AGENT
      if autoupdate
        useragent += ' autoupdate'
      end

      Dir.mktmpdir do |download_dir|

        # follow redirect, if one exists
        headers = Excon.head(
          url,
          :headers => {
            'User-Agent' => useragent
          }
        ).headers
        if headers['Location']
          url = headers['Location']
        end

        File.open("#{download_dir}/heroku.zip", "wb") do |file|
          file.print Excon.get(url).body
        end

        Zip::ZipFile.open("#{download_dir}/heroku.zip") do |zip|
          zip.each do |entry|
            target = File.join(download_dir, entry.to_s)
            FileUtils.mkdir_p File.dirname(target)
            zip.extract(entry, target) { true }
          end
        end

        FileUtils.rm "#{download_dir}/heroku.zip"

        old_version = latest_local_version
        new_version = client_version_from_path(download_dir)

        if old_version != new_version && maximum_version(old_version, new_version) == old_version
          return if @background_updating
          error "Installed version (#{old_version}) is newer than the latest available update (#{new_version})"
        end

        FileUtils.rm_rf updated_client_path
        FileUtils.mkdir_p File.dirname(updated_client_path)
        FileUtils.cp_r  download_dir, updated_client_path

        new_version
      end
    end

    def self.maximum_version(first_version, second_version)
      first_major, first_minor, first_patch, first_pre = first_version.split('.').map {|x| x.gsub(/\D/,'').to_i} + [0,0,0,0]
      second_major, second_minor, second_patch, second_pre = second_version.split('.').map {|x| x.gsub(/\D/,'').to_i} + [0,0,0,0]

      if first_major > second_major ||
        (first_major == second_major && first_minor > second_minor) ||
        (first_major == second_major && first_minor == second_minor && first_patch > second_patch) ||
        (first_major == second_major && first_minor == second_minor && first_patch == second_patch && first_pre > second_pre)
        first_version
      else
        second_version
      end
    end

    def self.inject_libpath
      background_update!

      old_version = client_version_from_path(installed_client_path)
      new_version = client_version_from_path(updated_client_path)
      if old_version != new_version && maximum_version(old_version, new_version) == new_version
        $:.unshift File.join(updated_client_path, "lib")
        vendored_gems = Dir[File.join(updated_client_path, "vendor", "gems", "*")]
        vendored_gems.each do |vendored_gem|
          $:.unshift File.join(vendored_gem, "lib")
        end
        load('heroku/updater.rb') # reload updated updater
      end
    end

    def self.background_update!
      if File.exists?(File.join(home_directory, ".heroku", "autoupdate"))
        pid = fork do
          begin
            require "excon"
            latest_version = json_decode(Excon.get('http://rubygems.org/api/v1/gems/heroku.json').body)['version']

            if Gem::Version.new(latest_version) > latest_local_version
              @background_updating = true
              update
            end
          rescue Exception => ex
            # trap all errors
          ensure
            @background_updating = false
          end
        end
        Process.detach pid
      end
    end
  end
end
