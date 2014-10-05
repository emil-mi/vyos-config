require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_host_name).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path == 'system host-name'
  end

  def section_path(inst_name)
    'system host-name '+ quote(inst_name)
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    VyattaConfigSection.new :path=>section_path(resource[:name])
  end

  def perform_update
    perform_create
  end
end
