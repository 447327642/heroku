require "heroku/command/base"

# manage apps (create, destroy)
#
class Heroku::Command::Apps < Heroku::Command::Base

  # apps
  #
  # list your apps
  #
  def index
    list = heroku.list
    if list.size > 0
      hputs(list.map {|name, owner|
        if heroku.user == owner
          name
        else
          "#{name.ljust(25)} #{owner}"
        end
      }.join("\n"))
    else
      hputs("You have no apps.")
    end
  end

  alias_command "list", "apps"

  # apps:info
  #
  # show detailed app information
  #
  # -r, --raw  # output info as raw key/value pairs
  #
  def info
    name = extract_app
    attrs = heroku.info(name)

    if options[:raw] then
      attrs.keys.sort_by { |a| a.to_s }.each do |key|
        case key
        when :addons then
          hputs("addons=#{attrs[:addons].map { |a| a["name"] }.sort.join(",")}")
        when :collaborators then
          hputs("collaborators=#{attrs[:collaborators].map { |c| c[:email] }.sort.join(",")}")
        else
          hputs("#{key}=#{attrs[key]}")
        end
      end
    else
      display "=== #{attrs[:name]}"
      display "Web URL:        #{attrs[:web_url]}"
      display "Domain Name:    #{attrs[:domain_name]}" if attrs[:domain_name]
      display "Git Repo:       #{attrs[:git_url]}"
      display "Dynos:          #{attrs[:dynos]}" unless attrs[:stack] == "cedar"
      display "Workers:        #{attrs[:workers]}" unless attrs[:stack] == "cedar"
      display "Repo Size:      #{format_bytes(attrs[:repo_size])}" if attrs[:repo_size]
      display "Slug Size:      #{format_bytes(attrs[:slug_size])}" if attrs[:slug_size]
      display "Stack:          #{attrs[:stack]}" if attrs[:stack]

      if attrs[:dyno_hours].is_a?(Hash)
        formatted_hours = attrs[:dyno_hours].keys.map do |type|
          "%s - %0.2f dyno-hours" % [ type.to_s.capitalize, attrs[:dyno_hours][type] ]
        end
        display "Dyno Usage:     %s" % formatted_hours.join("\n                ")
      end

      if attrs[:database_size]
        data = format_bytes(attrs[:database_size])
        if tables = attrs[:database_tables]
          data = data.gsub('(empty)', '0K') + " in #{quantify("table", tables)}"
        end
        display "Data Size:      #{data}"
      end

      if attrs[:cron_next_run]
        display "Next Cron:      #{format_date(attrs[:cron_next_run])} (scheduled)"
      end
      if attrs[:cron_finished_at]
        display "Last Cron:      #{format_date(attrs[:cron_finished_at])} (finished)"
      end

      unless attrs[:addons].empty?
        display "Addons:         " + attrs[:addons].map { |a| a['description'] }.join(', ')
      end

      display "Owner:          #{attrs[:owner]}"
      collaborators = attrs[:collaborators].delete_if { |c| c[:email] == attrs[:owner] }
      unless collaborators.empty?
        first = true
        lead = "Collaborators:"
        attrs[:collaborators].each do |collaborator|
          display "#{first ? lead : ' ' * lead.length}  #{collaborator[:email]}"
          first = false
        end
      end

      if attrs[:create_status] != "complete"
        display "Create Status:  #{attrs[:create_status]}"
      end
    end
  end

  alias_command "info", "apps:info"

  # apps:create [NAME]
  #
  # create a new app
  #
  #     --addons ADDONS        # a list of addons to install
  # -b, --buildpack BUILDPACK  # a buildpack url to use for this app
  # -r, --remote REMOTE        # the git remote to create, default "heroku"
  # -s, --stack STACK          # the stack on which to create the app
  #
  def create
    remote  = extract_option('--remote', 'heroku')
    stack   = extract_option('--stack', 'aspen-mri-1.8.6')
    timeout = extract_option('--timeout', 30).to_i
    name    = args.shift.downcase.strip rescue nil
    name    = heroku.create_request(name, {:stack => stack})
    hputs("Creating #{name}...", false)
    info    = heroku.info(name)
    begin
      Timeout::timeout(timeout) do
        loop do
          break if heroku.create_complete?(name)
          hprint(".")
          sleep 1
        end
      end
      hputs(" done, stack is #{info[:stack]}")

      (options[:addons] || "").split(",").each do |addon|
        addon.strip!
        hprint("Adding #{addon} to #{name}... ")
        heroku.install_addon(name, addon)
        hputs("done")
      end

      if buildpack = options[:buildpack]
        heroku.add_config_vars(name, "BUILDPACK_URL" => buildpack)
      end

      hputs([ info[:web_url], info[:git_url] ].join(" | "))
    rescue Timeout::Error
      hputs("Timed Out! Check heroku info for status updates.")
    end

    create_git_remote(name, remote || "heroku")
  end

  alias_command "create", "apps:create"

  # apps:rename NEWNAME
  #
  # rename the app
  #
  def rename
    name    = extract_app
    newname = args.shift.downcase.strip rescue ''
    raise(Heroku::Command::CommandFailed, "Must specify a new name.") if newname == ''

    heroku.update(name, :name => newname)

    info = heroku.info(newname)
    hputs([ info[:web_url], info[:git_url] ].join(" | "))

    if remotes = git_remotes(Dir.pwd)
      remotes.each do |remote_name, remote_app|
        next if remote_app != name
        if has_git?
          git "remote rm #{remote_name}"
          git "remote add #{remote_name} git@#{heroku.host}:#{newname}.git"
          hputs("Git remote #{remote_name} updated")
        end
      end
    else
      hputs("Don't forget to update your Git remotes on any local checkouts.")
    end
  end

  alias_command "rename", "apps:rename"

  # apps:open
  #
  # open the app in a web browser
  #
  def open
    app = heroku.info(extract_app)
    url = app[:web_url]
    hputs("Opening #{url}")
    Launchy.open url
  end

  alias_command "open", "apps:open"

  # apps:destroy
  #
  # permanently destroy an app
  #
  def destroy
    app = extract_app
    heroku.info(app) # fail fast if no access or doesn't exist

    if confirm_command(app)
      hprint "Destroying #{app} (including all add-ons)... "
      heroku.destroy(app)
      if remotes = git_remotes(Dir.pwd)
        remotes.each do |remote_name, remote_app|
          next if app != remote_app
          git "remote rm #{remote_name}"
        end
      end
      hputs("done")
    end
  end

  alias_command "destroy", "apps:destroy"

end
