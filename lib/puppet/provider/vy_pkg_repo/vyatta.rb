require File.dirname(__FILE__) + '/../VyattaConfigProvider'

#TODO: nu fac minic cu :pub_key
Puppet::Type.type(:vy_pkg_repo).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  # @param [VyattaConfigSection] section
  def self.section_matches?(section)
    section.parent.full_path == 'system package repository'
  end

  def section_path(inst_name)
    'system package repository '+ quote(inst_name)
  end

  def in_sync?
    super resource[:match_mode]
  end

  def normalize_single_section(acc,s)
    ret = if ['username','password'].include?(s.name) and s.leaves.first.name.empty?
	nil
    elsif s.empty? and s.name.include? " "
      s.name.split.sort.each { |n|
        acc << n
      }
      acc
    else
	super
    end
    ret
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    should_be_hash = resource.to_hash.reduce({}) { |ret,(n,v)|
      if [:url,:distribution,:password,:username].include? n
        ret[n.to_s]={ v => {}}
      elsif n==:components
        v = v.split if v.is_a? String
        ret[n.to_s]={ v.sort.join(' ') => {} }
      end
      ret
    }
    VyattaConfigSection.new :path=>section_path(resource[:name]), :hash=> should_be_hash
  end

  def perform_update
    to_delete=[]
    if resource[:match_mode]==:inclusive
      to_delete = self.section-should_be_section
    end
    to_create=should_be_section-self.section

    #reject sections that are empty or would be overwritten anyway
    to_delete = to_delete.reject { |d|
      (['username','password'].include?(d.name) and d.leaves.first.name.empty?) or
          to_create.any? { |c|
            d.parent.full_path == c.parent.full_path
          }
    }

    update_commands = []
    update_commands += to_delete.map {|s|
      %-delete #{s.full_path}- #pentru alte sectiuni e nevoie de o alta logica
    }
    update_commands += to_create.map {|s|
      if s.parent.name=='components' and resource[:match_mode]==:minimum
        existing_components = []
        self.section.select { |c|
          if c.parent.name=='components'
            existing_components=c.name.split
          end
        }
        existing_components+=s.name.split
        %-set #{s.parent.full_path} '#{existing_components.sort.uniq.join(' ')}'-
      else
        %-set #{s.full_path}-
      end
    }
    exec_config_commands update_commands.sort
  end

  def fetch_property_value(property)
    normalized_section = normalize_config_section self.section
    case property
      when :url
        normalized_section.select { |s| s.parent.name == 'url' }.map { |s| s.name }.first
      when :distribution
        normalized_section.select { |s| s.parent.name == 'distribution' }.map { |s| s.name }.first
      when :password
        normalized_section.select { |s| s.parent.name == 'password' }.map { |s| s.name }.first
      when :username
        normalized_section.select { |s| s.parent.name == 'username' }.map { |s| s.name }.first
      when :components
        normalized_section.select { |s| s.parent.name == 'components' }.map { |s| s.name }
      else
        super
    end
  end
end
