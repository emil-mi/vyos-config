Puppet::Type.newtype(:vy_interface) do
  @doc = "Manage a network interface entry in vyatta"
  
  ensurable do
    desc "Valid values are enabled or up, disabled or down and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "Name of interface"
  end

  newparam(:identifier) do
    desc "Identifier of the interface equal to name if missing. Can be any valid linux interface name or a mac address"
  end

  newparam(:description) do
    desc "Description of interface"
  end
  
  newparam(:dns_names) do
    desc "DNS name that resolves to this interface. Can be an array of names in wich case the first is the name and the rest are aliases"
  end

 end
