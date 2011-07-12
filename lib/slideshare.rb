require 'net/http'
require 'digest/sha1'
require 'active_support/core_ext'

# referred rubytter gem (written by jugyo).
class SlideShare
	HOST = 'www.slideshare.net'
	PATH_PREFIX = '/api/2'

	class APIError < StandardError
		attr_reader :response
		def initialize(msg, response = nil)
			super(msg)
			@response = response
		end
	end

	def initialize(api_key, secret_key)
		@api_key = api_key
		@secret_key = secret_key
	end

	def get_slideshow(params = {})
		get('/get_slideshow', params)
	end

	def search_slideshows(params = {})
		get('/search_slideshows', params)
	end

	def get(path, params = {})
		param_str = '?' + to_param_str(params)
		path = path + param_str unless param_str.empty?
		req = Net::HTTP::Get.new(PATH_PREFIX + path)
		structize(http_request(HOST, req))
	end

	def http_request(host, req, param_str = nil)
		res = Net::HTTP.start(host) do |http|
			if param_str
				http.request(req, param_str)
			else
				http.request(req)
			end
		end
		data = Hash.from_xml res.body
		raise APIError.new(res.body, res) unless res.code == '200'
		raise APIError.new(data['SlideShareServiceError']['Message'], res) unless data['SlideShareServiceError'].nil?
		structize data
	end

	def structize(data)
		case data
		when Array
			data.map{|i| structize(i)}
		when Hash
			class << data
				def id
					self[:id]
				end

				def to_hash(obj = self)
					obj.inject({}) {|memo, (key, value)|
					 memo[key] = (value.kind_of? obj.class) ? to_hash(value) : value
					memo
					}
				end

				def method_missing(name, *args)
					self[name]
				end
			end

			data.keys.each do |k|
				case k
				when String, Symbol
					data[k] = structize(data[k])
				else
					data.delete(k)
				end
			end

			data.symbolize_keys!
		else
			case data
			when String
				CGI.unescapeHTML(data)
			else
				data
			end
		end
	end

	def to_param_str(hash)
		raise ArgumentError, 'Argument must be a Hash object' unless hash.is_a?(Hash)
		timestamp = Time.now.to_i
		sha1 = Digest::SHA1.hexdigest("#{@secret_key}#{timestamp}")
		hash.merge!(:api_key => @api_key, :ts => timestamp, :hash => sha1)
		hash.to_a.map{|i| i[0].to_s + '=' + CGI.escape(i[1].to_s) }.join('&')
	end
end
