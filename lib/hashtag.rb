class Hashtag
  class << self
    attr_writer :file

    def list
      @list ||= YAML.load_file(@file)
    end

    def detect(str)
      list.each do |s|
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
end
