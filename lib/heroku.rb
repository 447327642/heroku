require 'net/http'
require 'yaml'
require 'rexml/document'
require 'fileutils'

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

	def get(uri, extra_headers={})
		transmit Net::HTTP::Get.new(uri, headers.merge(extra_headers))
	end

	def post(uri, payload="")
		transmit Net::HTTP::Post.new(uri, headers), payload
	end

	def put(uri, payload, extra_headers={})
		transmit Net::HTTP::Put.new(uri, headers.merge(extra_headers)), payload
	end

	def delete(uri)
		transmit Net::HTTP::Delete.new(uri, headers)
	end

	class RequestFailed < Exception
		def initialize(msg); @res = msg; end
		def to_s; "#{self.class} with HTTP code #{@res.code}"; end
	end

	def transmit(req, payload=nil)
		req.basic_auth user, password
		Net::HTTP.start(host) do |http|
			res = http.request(req, payload)
			unless %w(200 201 202).include? res.code
				raise RequestFailed, res
			else
				res.body
			end
		end
	end

	def headers
		{ 'Accept' => 'application/xml', 'X-Heroku-API-Version' => '1' }
	end

	def xml(raw)
		REXML::Document.new(raw)
	end
end
