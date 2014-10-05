require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_user).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path == 'system login user'
  end

  def fetch_property_value(property)
    normalized_section = normalize_config_section self.section
    case property
      when :ensure
        set_password = normalized_section.select { |s| s.parent.name == 'encrypted-password' }.map { |s| s.name }.first
        if set_password and set_password[0]=='!'
          return :disabled
        end
        set_level = normalized_section.select { |s| s.parent.name == 'level' }.map { |s| s.name }.first
        if set_level
          return set_level.intern
        else
          return :absent
        end
      when :password
        normalized_section.select { |s| s.parent.name == 'encrypted-password' }.map { |s| s.name }.first
      when :full_name
        normalized_section.select { |s| s.parent.name == 'full-name' }.map { |s| s.name }.first
      when :home
        normalized_section.select { |s| s.parent.name == 'home-directory' }.map { |s| s.name }.first
      when :encryption
        'none'
      when :group
        normalized_section.select { |s| s.parent.name == 'group' }.map { |s| s.name }
      else
        super
    end
  end

  def section_path(inst_name)
    'system login user '+ quote(inst_name)
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    should_be_hash = resource.to_hash.reduce({}) { |ret,(n,v)|
      if n==:group
        v=[v] unless v.is_a? Array
        ret[n.to_s]=v.reduce({}) {  |acc,usr_grp|
          acc[usr_grp]={}
          acc
        }
      elsif n==:home
        ret['home-directory'] = { v => {} }
      elsif n==:full_name
        ret['full-name'] = { v => {} }
      elsif n==:password
        ret['authentication']={ 'encrypted-password' => { v => {} }}
      elsif n==:ensure
        ret['level'] = { (v.to_s=='admin'?'admin':'operator') => {} }
      end
      ret
    }
    VyattaConfigSection.new :path=>section_path(resource[:name]), :hash=> should_be_hash
  end

  def perform_update
    to_delete = self.section-should_be_section
    to_create=should_be_section-self.section

    to_delete = to_delete.map { |s|
      s.leaves
    }.flatten

    to_create = to_create.map { |s|
      s.leaves
    }.flatten

    #reject sections that are empty or would be overwritten anyway
    to_delete = to_delete.reject { |d|
      (d.parent.name=='group' and resource[:group_membership].to_s=='minimum') or
          to_create.any? { |c|
            d.parent.full_path == c.parent.full_path
          }
    }

    update_commands = []
    update_commands += to_delete.map {|s|
      %-delete #{s.full_path}- #pentru alte sectiuni e nevoie de o alta logica
    }

    update_commands += to_create.map {|s|
      %-set #{s.full_path}-
    }
    exec_config_commands update_commands.sort
  end

end
