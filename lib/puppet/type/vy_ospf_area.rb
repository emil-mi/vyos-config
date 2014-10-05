Puppet::Type.newtype(:vy_ospf_area) do
  @doc = "Manage an OSPF area entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "OSPF area in decimal or dotted decimal notation"
  end

  newparam(:area) do
    desc "OSPF area in decimal or dotted decimal notation equal to name if missing"
  end

  newparam(:network) do
    desc "IPv4 address/mask of OSPF network. Maybe an interface address matching this should be autorequired?"
  end
  
end
