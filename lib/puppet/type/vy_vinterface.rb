Puppet::Type.newtype(:vy_vinterface) do
  @doc = "Manage a VLAN network interface entry in vyatta"
  
  ensurable do
    desc "Valid values are enabled or up, disabled or down and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "Name of interface in the form interface_name/vlan_id"
  end

  newparam(:vlan) do
    desc "VLAN identifier of the interface equal to name if missing."
    newvalues(/^\d+/)
  end

  newparam(:interface) do
    desc "Interface on wich to define the vinterface equal to name if missing. It is auto-required"
  end
  
  newparam(:description) do
    desc "Description of interface"
  end
  
  newparam(:dns_names) do
    desc "DNS name that resolves to this interface. Can be an array of names in wich case the first is the name and the rest are aliases"
  end

 end
