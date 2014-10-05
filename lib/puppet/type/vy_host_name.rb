Puppet::Type.newtype(:vy_host_name) do
  @doc = "Manage the host name entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "FQDN of host or just the name"
  end

  newparam(:domain) do
    desc "The DNS domain name"
  end
 end
