class Hashtag
	def initialize(source = [])
		raise StandardError, 'require word' if source.size.zero?
		@source = source
	end

	def detect(str)
		@source.each do |s|
			if str =~ /#{s}/i
				return "##{s}"
			end
		end
		nil
	end

	def detect_array(array = [])
		array = [array] if array.is_a?(String)
		array.each do |s|
			ret = detect(s)
			return ret if ret
		end
		nil
	end
end
