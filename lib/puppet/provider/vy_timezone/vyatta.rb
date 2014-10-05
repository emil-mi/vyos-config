require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_timezone).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods

  def self.section_matches?(section)
    section.parent.full_path == 'system time-zone'
  end

  def section_path(inst_name)
    'system time-zone '+ quote(inst_name)
  end

  # @return [VyattaConfigSection] The configuration section that is the minimum requirement given the
  # puppet resource parameters
  def should_be_section
    VyattaConfigSection.new :path=>section_path(resource[:name])
  end

  def perform_delete
    delete_commands =['delete system time-zone']
    exec_config_commands delete_commands.sort
  end

  def perform_update
    perform_create
  end

end
