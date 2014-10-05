Puppet::Type.newtype(:vy_timezone) do
  @doc = "Manage the system time-zone entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
    defaultto :present
  end

  newparam(:name,:namevar=>true) do
    desc "Name of time-zone in 'region/city' form or 'ETC/TzSpec'"
  end

 end
