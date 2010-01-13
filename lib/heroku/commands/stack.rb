module Heroku::Command
	class Stack < BaseWithApp
		def list
			list = heroku.list_stacks(app)
			lines = list.map do |stack|
				if stack['current']
					"* #{stack['name']}"
				else
					"  #{stack['name']}"
				end
			end
			display lines.join("\n")
		end
		alias :index :list
	end
end
