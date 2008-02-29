require 'net/http'
require 'yaml'
require 'rexml/document'
require 'fileutils'

# A Ruby class to call the Heroku REST API.  You might use this if you want to
# manage your Heroku apps from within a Ruby program, such as Capistrano; but
# more commonly, you'll want to use the "heroku" binary from the command line.
# 
# Example:
# 
# require 'heroku'
# heroku = Heroku.new('me@example.com', 'mypass')
# heroku.create('myapp')
#
class Heroku
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

	def destroy(name)
		delete("/apps/#{name}")
	end

	def upload_authkey(key)
		put("/user/authkey", key, { 'Content-Type' => 'text/ssh-authkey' })
	end

	##################

	def get(uri, extra_headers={})    # :nodoc:
		transmit Net::HTTP::Get.new(uri, headers.merge(extra_headers))
	end

	def post(uri, payload="")    # :nodoc:
		transmit Net::HTTP::Post.new(uri, headers), payload
	end

	def put(uri, payload, extra_headers={})    # :nodoc:
		transmit Net::HTTP::Put.new(uri, headers.merge(extra_headers)), payload
	end

	def delete(uri)    # :nodoc:
		transmit Net::HTTP::Delete.new(uri, headers)
	end

	def transmit(req, payload=nil)    # :nodoc:
		req.basic_auth user, password
		Net::HTTP.start(host) do |http|
			process_result http.request(req, payload)
		end
	end

	# Bad return value from the webserver, check the request body for the
	# specific error message.
	class RequestFailed < Exception; end

	# Heroku user and password supplied were not valid.
	class Unauthorized < Exception; end

	def process_result(res)   # :nodoc:
		if %w(200 201 202).include? res.code
			res.body
		elsif res.code == "401"
			raise Unauthorized
		else
			raise RequestFailed, error_message(res)
		end
	end

	def parse_error_xml(body)   # :nodoc:
		xml(body).elements.to_a("//errors/error").map { |a| a.text }.join(" / ")
	rescue
		"unknown error"
	end

	def error_message(res)   # :nodoc:
		"HTTP code #{res.code}: #{parse_error_xml(res.body)}"
	end

	def headers   # :nodoc:
		{ 'Accept' => 'application/xml', 'X-Heroku-API-Version' => '1' }
	end

	def xml(raw)   # :nodoc:
		REXML::Document.new(raw)
	end
end
