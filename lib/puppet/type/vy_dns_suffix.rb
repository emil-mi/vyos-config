Puppet::Type.newtype(:vy_dns_suffix) do
  @doc = "Manage a DNS search domanin entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "FQDN to search"
  end

  newparam(:domain) do
    desc "FQDN to search equal to name if missing"
  end
 end
 