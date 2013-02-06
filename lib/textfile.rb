class Textfile
  class << self
    attr_accessor :basedir
  end

  attr_reader :file

  def initialize file
    @file = File.expand_path(file, self.class.basedir)
    FileUtils.touch(@file) unless File.exist?(@file)
  end

  def read
    IO.read(@file)
  end

  def write str
    IO.write(@file, str, mode: 'w')
  end

  def append *strs
    IO.write(@file, "#{strs.join("\n")}\n", mode: 'a')
  end
end
