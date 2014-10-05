Puppet::Type.newtype(:vy_vrrp_group) do
  @doc = "Manage a VRRP group entry in vyatta"
  
  ensurable do
    desc "Valid values are present, absent and disable."
  end

  newparam(:name,:namevar=>true) do
    desc "Name of group as [v]interface/id"
  end

  newparam(:description) do
    desc "Description of interface"
  end
   
  newparam(:preempt) do
    desc "Preempt mode"
  end
   
  newparam(:preempt_delay) do
    desc "Preempt delay"
  end
   
  newparam(:priority) do
    desc "Priority"
  end
  
  newparam(:advertise-interval) do
    desc "Advertise interval"
  end
  
  newparam(:interface) do
    desc "Interface on wich to define the VRRP group equal to name if missing. It is auto-required"
  end
  
  newparam(:address) do
    desc "IPv4 address, IPv4 address/mask or vector of up to 20 IPv4 addresses to use"
  end
 end
