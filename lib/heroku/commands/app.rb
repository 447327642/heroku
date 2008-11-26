require 'readline'

module Heroku::Command
	class App < Base
		def list
			list = heroku.list
			if list.size > 0
				display list.join("\n")
			else
				display "You have no apps."
			end
		end

		def create
			name = args.shift.downcase.strip rescue nil
			name = heroku.create(name, {})
			display "Created #{app_urls(name)}"
		end

		def rename
			name = extract_app
			newname = args.shift.downcase.strip rescue ''
			raise(CommandFailed, "Invalid name.") if newname == ''

			heroku.update(name, :name => newname)

			display app_urls(newname)
			display "Don't forget to update your Git remotes on any local checkouts."
		end

		def info
			name = extract_app
			attrs = heroku.info(name)
			display "=== #{attrs[:name]}"
			display "Web URL:        http://#{attrs[:name]}.#{heroku.host}/"
			display "Domain name:    http://#{attrs[:domain_name]}/" if attrs[:domain_name]
			display "Git Repo:       git@#{heroku.host}:#{attrs[:name]}.git"
			display "Mode:           #{ attrs[:production] == 'true' ? 'production' : 'development' }"
			display "Code size:      #{format_bytes(attrs[:code_size])}" if attrs[:code_size]
			display "Data size:      #{format_bytes(attrs[:data_size])}" if attrs[:data_size]
			display "Public:         #{ attrs[:share_public] == 'true' ? 'true' : 'false' }"

			first = true
			lead = "Collaborators:"
			attrs[:collaborators].each do |collaborator|
				display "#{first ? lead : ' ' * lead.length}  #{collaborator[:email]} (#{collaborator[:access]})"
				first = false
			end
		end

		def rake
			app = extract_app
			cmd = args.join(' ')
			if cmd.length == 0
				display "Usage: heroku rake <command>"
			else
				display heroku.rake(app, cmd)
			end
		end

		def console
			app = extract_app
			cmd = args.join(' ').strip
			if cmd.empty?
				console_session
			else
				display heroku.console(app, cmd)
			end
		end

		def console_session
			app = extract_app
			display "Ruby console for #{app}.#{heroku.host}"
			heroku.console(app) do |console|
				while cmd = Readline.readline('>> ')
					break if cmd.downcase.strip == 'exit'
					unless cmd.nil? || cmd.strip.empty?
						Readline::HISTORY.push(cmd)
						display console.run(cmd)
					end
				end
			end
		end

		def restart
			app_name = extract_app
			heroku.restart(app_name)
			display "Servers restarted"
		end

		def destroy
			if name = extract_option('--app')
				heroku.destroy(name)
				display "Destroyed #{name}"
			else
				display "Set the app you want to destroy adding --app <app name> to this command"
			end
		end

		protected
			@@kb = 1024
			@@mb = 1024 * @@kb
			@@gb = 1024 * @@mb
			def format_bytes(amount)
				amount = amount.to_i
				return nil if amount == 0
				return amount if amount < @@kb
				return "#{(amount / @@kb).round}k" if amount < @@mb
				return "#{(amount / @@mb).round}M" if amount < @@gb
				return "#{(amount / @@gb).round}G"
			end

	end
end