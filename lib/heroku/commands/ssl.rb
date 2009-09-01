module Heroku::Command
	class Ssl < BaseWithApp
		def list
			heroku.list_domains(app).each do |d|
				if cert = d[:cert]
					display "#{d[:domain]} has a certificate issued by #{cert[:issuer]}, to #{cert[:subject]}, expiring at #{cert[:expires_at].strftime("%d/%m/%Y")}"
				else
					display "#{d[:domain]} has no certificate"
				end
			end
		end
		alias :index :list

		def add
			usage  = 'heroku ssl:add <domain> <pem> <key>'
			raise CommandFailed, "Missing domain. Usage:\n#{usage}"   unless domain   = args.shift
			raise CommandFailed, "Missing pem file. Usage:\n#{usage}" unless pem_file = args.shift
			raise CommandFailed, "Missing key file. Usage:\n#{usage}" unless key_file = args.shift
			raise CommandFailed, "Could not find pem in #{pem_file}"  unless File.exists?(pem_file)
			raise CommandFailed, "Could not find key in #{key_file}"  unless File.exists?(key_file)

			pem    = File.read(pem_file)
			key    = File.read(key_file)
			heroku.add_ssl(app, domain, pem, key)
			display "Added certificate to #{domain}"
		end

		def remove
			raise CommandFailed, "Missing domain. Usage:\nheroku ssl:remove <domain>" unless domain = args.shift
			heroku.remove_ssl(app, domain)
			display "Removed certificate from #{domain}"
		end
	end
end