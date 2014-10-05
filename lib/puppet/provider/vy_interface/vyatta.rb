require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_interface).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods
  
  def initialize(entry,*args)
    super
  end
end
