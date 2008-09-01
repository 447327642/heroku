require 'rubygems'
require 'rexml/document'
require 'rest_client'
require 'uri'

# A Ruby class to call the Heroku REST API.  You might use this if you want to
# manage your Heroku apps from within a Ruby program, such as Capistrano.
# 
# Example:
# 
#   require 'heroku'
#   heroku = Heroku::Client.new('me@example.com', 'mypass')
#   heroku.create('myapp')
#
class Heroku::Client
	attr_reader :host, :user, :password

	def initialize(user, password, host='heroku.com')
		@user = user
		@password = password
		@host = host
	end

	def list
		doc = xml(get('/apps'))
		doc.elements.to_a("//apps/app/name").map { |a| a.text }
	end

	def create(name=nil)
		uri = "/apps"
		uri += "?app[name]=#{name}" if name
		xml(post(uri)).elements["//app/name"].text
	end

	def update(name, attributes)
		uri = "/apps/#{name}"
		# rest-client doesn't support nested payloads yet at least
		payload = {}
		attributes.each { |k, v| payload["app[#{k}]"] = v }
		put(uri, payload)
	end

	def destroy(name)
		delete("/apps/#{name}")
	end

	# collaborators
	def list_collaborators(app_name)
		doc = xml(get("/apps/#{app_name}/collaborators"))
		doc.elements.to_a("//collaborators/collaborator").map do |a|
			{ :email => a.elements['user'].elements['email'].text, :access => a.elements['access'].text }
		end.select { |collaborator| collaborator[:email] != user }
	end

	def add_collaborator(app_name, email, access='view')
		xml(post("/apps/#{app_name}/collaborators", { 'collaborator[email]' => email, 'collaborator[access]' => access }))
	end

	def update_collaborator(app_name, email, access)
		put("/apps/#{app_name}/collaborators/#{escape(email)}", { 'collaborator[access]' => access })
	end

	def remove_collaborator(app_name, email)
		delete("/apps/#{app_name}/collaborators/#{escape(email)}")
	end

	def upload_authkey(key)
		put("/user/authkey", key, { 'Content-Type' => 'text/ssh-authkey' })
	end

	##################

	def resource(uri)
		RestClient::Resource.new(host + uri, user, password)
	end

	def get(uri, extra_headers={})    # :nodoc:
		resource(uri).get(heroku_headers.merge(extra_headers))
	end

	def post(uri, payload="")    # :nodoc:
		resource(uri).post(payload, heroku_headers)
	end

	def put(uri, payload, extra_headers={})    # :nodoc:
		resource(uri).put(payload, heroku_headers.merge(extra_headers))
	end

	def delete(uri)    # :nodoc:
		resource(uri).delete
	end

	def heroku_headers   # :nodoc:
		{ 'X-Heroku-API-Version' => '1' }
	end

	def xml(raw)   # :nodoc:
		REXML::Document.new(raw)
	end

	def escape(value)
		escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
		escaped.gsub('.', '%2E') # not covered by the previous URI.escape
	end
end
