require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_ip_address).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path =~ /^interfaces .+ address$/
  end

  def instance_name
    self.section.full_path =~ /^interfaces [^ ]+ ([^ ]+) (vif (\d+) )?address (.+)$/
    if $3
      "#{$1}:#{$3}/#{$4}"
    else
      "#{$1}/#{$4}"
    end
  end

  def section_path(addr,interface)
    case interface
      when /^(eth\d+)(:(\d+))?$/
        if $3
          "interfaces ethernet #{$1} vif #{$3} address #{addr}"
        else
          "interfaces ethernet #{$1} address #{addr}"
        end
      when /^lo\d*$/
        "interfaces loopback #{interface} address #{addr}"
      else
        self.fail "Unknown interface type"
    end
  end

  def addr_from_attributes(res)
    res[:address] ||
        if res[:name] =~ /^(((eth\d+)|(eth\d+:\d+)|(lo\d*))\/)?((dhcp)|(dhcpv6)|(.+))$/
          $6
        else
          res[:name]
        end
  end

  def if_from_attributes(res)
    res[:interface] ||
        if res[:name] =~ /^((eth\d+)|(eth\d+:\d+)|(lo\d*))\/((dhcp)|(dhcpv6)|(.+))$/
          $1
        else
          res[:name]
        end
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    VyattaConfigSection.new :path=>section_path(addr_from_attributes(resource),if_from_attributes(resource))
  end

  def manages_resource?(name,res)
    self.section.full_path =~ /^interfaces [^ ]+ ([^ ]+) (vif (\d+) )?address (.+)$/
    if $3
      res[:interface]=="#{$1}:#{$3}" and res[:address]=="#{$4}"
    else
      res[:interface]=="#{$1}" and res[:address]=="#{$4}"
    end
  end

  def perform_update
  end

end
