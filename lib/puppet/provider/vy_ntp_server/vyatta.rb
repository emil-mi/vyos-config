require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_ntp_server).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path == 'system ntp server'
  end

  def section_path(inst_name)
    'system ntp server '+ quote(inst_name)
  end

  def addr_from_attributes(res)
    res[:address] || res[:name]
  end

  def should_be_section
    should_be_hash = resource.to_hash.reduce({}) { |ret,(n,v)|
      if [:dynamic,:preempt,:prefer].include? n and v
        ret[n.to_s]={}
      elsif n==:ensure and v==:disabled
        ret['noselect'] = {}
      end
      ret
    }
    VyattaConfigSection.new :path=>section_path(addr_from_attributes(resource)), :hash=> should_be_hash
  end

  def manages_resource?(name,res)
    self.section.name == addr_from_attributes(res)
  end

  def perform_update
    to_delete = self.section-should_be_section
    to_create = should_be_section-self.section

    update_commands = []
    update_commands += to_delete.map {|s|
      %-delete #{s.parent.full_path}- #pentru alte sectiuni e nevoie de o alta logica
    }
    update_commands += to_create.map {|s|
      %-set #{s.full_path}-
    }
    exec_config_commands update_commands
  end

  def fetch_property_value(property)
    normalized_section = normalize_config_section self.section
    case property
      when :ensure
        is_disabled = normalized_section.select { |s| s.name == 'noselect' }.any?
        if is_disabled
          return :disabled
        end
        return :present
      when :dynamic
        normalized_section.select { |s| s.name == 'dynamic' }.any?
      when :preempt
        normalized_section.select { |s| s.name == 'preempt' }.any?
      when :prefer
        normalized_section.select { |s| s.name == 'prefer' }.any?
      else
        super
    end
  end

end
