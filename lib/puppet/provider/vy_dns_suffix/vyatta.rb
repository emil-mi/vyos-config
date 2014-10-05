require File.dirname(__FILE__) + '/../VyattaConfigProvider'

Puppet::Type.type(:vy_dns_suffix).provide :vyatta, :parent=>VyattaConfigProvider do
  desc ""

  mk_resource_methods
  
  def initialize(entry,*args)
    super
  end
end
