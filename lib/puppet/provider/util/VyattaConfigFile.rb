require File.dirname(__FILE__) + '/VyattaConfigSection'

class VyattaConfigFile < VyattaConfigSection

  # @param [*String] str array of commands that describe the configuration
  # @return [VyattaConfigFile] the equivalent configuration file object
  def self.parse(str)
    return nil unless str
    root = new
    root.parse str
    return root
  end

  def parse(str)
    str.split("\n").each { |line|
      if line.strip=~/^set((\s+(([^ \t']+)|('([^']*)')))+)\s*$/
        path = self.class.split_path($1)
        create_section( path )
      end
    }
  end

  def initialize(settings={})
    super
  end
end

