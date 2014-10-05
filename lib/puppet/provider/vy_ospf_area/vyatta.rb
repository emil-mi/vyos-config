require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_ospf_area).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods
  
  def initialize(entry,*args)
    super
  end
end
