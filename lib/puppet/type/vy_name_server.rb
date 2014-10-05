require 'ipaddr'

Puppet::Type.newtype(:vy_name_server) do
  @doc = "Manage a name server entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
  end

  newparam(:name,:namevar=>true) do
    desc "IP address of DNS server"
  end

  newparam(:address) do
    desc "IP address of DNS server equal to name if missing"

    munge do |value|
      if value.empty?
        resource[:name]
      else
        value
      end
    end

    defaultto ''
  end

  validate do
    address = self[:address]
    valid = begin
      IPAddr.new(address).to_s
    rescue
      nil
    end
    self.fail "Address must be either an IPv4 or IPv6 address, not #{address.inspect}" if valid.nil?
  end
 end
