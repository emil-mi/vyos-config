require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_name_server).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path == 'system name-server'
  end

  def section_path(inst_name)
    'system name-server '+ quote(inst_name)
  end

  def addr_from_attributes(res)
    res[:address] || res[:name]
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    VyattaConfigSection.new :path=>section_path(addr_from_attributes(resource))
  end

  def manages_resource?(name,res)
    self.section.name == addr_from_attributes(res)
  end

  def perform_update
    perform_create
  end

end
