require 'commands/base'

module Heroku
	module Command
		class InvalidCommand < RuntimeError; end
		class CommandFailed  < RuntimeError; end

		class << self
			def run(command, args)
				run_internal(command, args)
			rescue InvalidCommand
				display "Unknown command. Run 'heroku help' for usage information."
			rescue RestClient::Unauthorized
				display "Authentication failure"
			rescue RestClient::ResourceNotFound
				display "Resource not found.  (Did you mistype the app name?)"
			rescue RestClient::RequestFailed => e
				display extract_error(e.response)
			rescue CommandFailed => e
				display e.message
			end

			def run_internal(command, args)
				namespace, command = parse(command)
				require "commands/#{namespace}"
				klass = Heroku::Command.const_get(namespace.capitalize).new(args)
				raise InvalidCommand unless klass.respond_to?(command)
				klass.send(command)
			end

			def display(msg)
				puts(msg)
			end

			def parse(command)
				parts = command.split(':')
				case parts.size
					when 1
						if namespaces.include? command
							return command, 'index'
						else
							return 'app', command
						end
					when 2
						raise InvalidCommand unless namespaces.include? parts[0]
						return parts
					else
						raise InvalidCommand
				end
			end

			def namespaces
				@@namespaces ||= Dir["#{File.dirname(__FILE__)}/commands/*"].map do |namespace|
					namespace.gsub(/.*\//, '').gsub(/\.rb/, '')
				end
			end

			def extract_error(response)
				return "Not found" if response.code.to_i == 404

				msg = parse_error_xml(response.body) rescue ''
				msg = 'Internal server error' if msg.empty?
				msg
			end

			def parse_error_xml(body)
				xml_errors = REXML::Document.new(body).elements.to_a("//errors/error")
				xml_errors.map { |a| a.text }.join(" / ")
			end
		end
	end
end