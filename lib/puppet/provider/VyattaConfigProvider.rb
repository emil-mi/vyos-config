require 'puppet/provider'
require File.dirname(__FILE__) + '/util/VyattaConfigFile'
require 'open3'

class VyattaConfigProvider < Puppet::Provider

  def self.section_matches?(the_section)
    raise Puppet::DevError, "Provider #{self.name} has not defined the 'section_matches' class method"
  end

  def instance_name
    self.section.name
  end

  def should_be_section
    raise Puppet::DevError, "Provider #{self.name} has not defined the 'should_be_section' method"
  end

  def fetch_property_value(property)
    raise Puppet::DevError,
      "Provider #{self.name} has not defined "+
          "the 'fetch_property_value' method for #{property}" if property!=:ensure
    nil
  end

  def in_sync?(mode=:inclusive)
    return false unless self.section
    should_be=normalize_config_section should_be_section
    normalized_section = normalize_config_section self.section
    ret = if mode==:minimum
      normalized_section.superset? should_be
    else
      normalized_section.superset?(should_be) and should_be.superset?(normalized_section)
    end
    #puts "#{resource[:name]} is #{normalized_section} and should be #{should_be} wich is #{ret}"
    ret
  end

  def self.config_statements
    execute(["/opt/vyatta/bin/vyatta-op-cmd-wrapper",'show','configuration','commands']).split("\n")
  end

  def self.prefetch(resources)
    Puppet[:trace]=true
    all_instances = instances
    resources.each do |name, resource|
      #puts "prefetch #{name} for #{resource.to_hash.inspect}"
      result = all_instances.detect { |p|
        p.manages_resource?(name,resource)
      }
      if result
        resource.provider = result
      else
        the_section = nil #todo lookup section in config file
        resource.provider = new(the_section)
        #resource.provider.@property_hash == result din ctor si resource.provider.resource este null? pana dupa asignare
      end
      #resource.provider.resource este setat la resource si resource.provider.@section este setat la the_section
    end
  end

  def self.instances
    #todo find all sections matching this type's prefix
    cfg_file=VyattaConfigFile.parse(config_statements.join("\n"))
    cfg_file.select { |s|
      section_matches? s
    }.map { |s| new(s, :ensure=>:present) }
  end

  def manages_resource?(name,res)
    self.name == name
  end

  attr_accessor :section
  def section=(the_section)
    @section = the_section
    if the_section
      valid_props = self.class.resource_type.validproperties
      valid_props.each do |property|
        if (val = fetch_property_value(property))
          @property_hash[property] = val
        end
      end
    end
    the_section
  end

  def initialize(the_section,*args)
    if the_section.is_a?(VyattaConfigSection) or not the_section
      super(*args)
      self.section=the_section
    else
      args = [the_section] + args
      super(*args)
      self.section=nil
    end
    #@property_hash == args[0] - minim :ensure este setat din #prefetch
  end

  def name
    return super if self.resource
    instance_name
  end

  def resource=(res)
    super
    status =  in_sync? ? :present : :absent
    self.class.resource_type.validproperties.each do |property|
      if @property_hash.has_key?(property) and not res.parameter(property)
        res[property]=@property_hash[property] if
          property != :ensure or not [:present,:absent].include? @property_hash[:ensure]
      else
        if property == :ensure
          @property_hash[:ensure] = status
        end
      end
    end

    status = :updatable if status==:absent and self.section
    #puts "Resource #{res[:name]} is #{status} and should be #{res[:ensure]}"
  end

  def to_s
    %- #{super}#{@property_hash.inspect} #{@section.inspect} -
  end

  def exists?
    #:ensure este setat din #prefetch
    (@property_hash[:ensure] != :absent and not @property_hash[:ensure].nil?)
  end

  def create
    #puts "Create #{resource[:name]}"
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if (val = resource.should(property))
        @property_hash[property] = val
      end
    end
  end

  def destroy
    #puts "Destroy #{resource[:name]}"
    @property_hash[:ensure] = :absent
  end

  def flush
    #todo write settings to config file
    #puts "Flush #{resource[:name]} with #{@property_hash.inspect} and #{resource.to_hash.inspect}"
    if @property_hash[:ensure]==:absent
      perform_delete
    else
      if section
        perform_update
      else
        perform_create
      end
    end
    @property_hash.clear
  end

  protected

  def exec_config_commands(commands)
    cfg_wrapper='/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper'
    cmd_output=cmd_err=''
    bash_opts=Puppet[:debug] ? '-v' : '' #'-vn'
    Open3.popen3('sg vyattacfg -c bash '+bash_opts) { |i,o,e|
	i.puts "source /etc/default/vyatta";
	i.puts "#{cfg_wrapper} begin"
	commands.each { |cmd|
	    i.puts "#{cfg_wrapper} #{cmd}"
	}
	i.puts "#{cfg_wrapper} commit"
	i.puts "#{cfg_wrapper} save"
	i.puts "#{cfg_wrapper} end"
	i.close
	cmd_output=o.read
	cmd_err=e.read
    }
    resource.err cmd_err.inspect unless cmd_err.strip.empty?
    resource.debug cmd_output.inspect unless cmd_output.strip.empty?
  end

  def perform_delete
    changes = self.section.root.track_changes {
      self.section.parent.delete section
    }
    delete_commands = changes.map { |change|
      ops = {:add=>'set',:delete=>'delete'}
      %-#{ops[change.type]} #{change.section.full_path}-
    }
    exec_config_commands delete_commands.sort
  end

  def perform_update
    raise Puppet::DevError, "Provider #{self.name} has not defined the 'perform_update' method"
  end

  def perform_create
    should_be = should_be_section
    puts "Create for #{resource[:name]} to #{should_be}"
    change_commands = VyattaConfigSection.new.track_changes { |root|
      root << should_be.root
    }.reduce([]) { |acc,change|
      acc  + change.section.leaves
    }.uniq.map { |s|
      %-set #{s.full_path}-
    }
    exec_config_commands change_commands.sort
  end

  def normalize_single_section(acc,s)
    if s.empty? and s.name.include? " "
      s.name.split.each { |n|
        acc << n
      }
      acc
    else
      acc << normalize_config_section(s)
    end
  end

  def normalize_config_section(the_section)
    ret=VyattaConfigSection.new :name=>the_section.name, :parent=>the_section.parent
    the_section.accumulate(ret) { |acc,s|
      normalize_single_section(acc,s)
    }
    ret
  end

  def quote(str)
    VyattaConfigSection.quote str
  end
end
