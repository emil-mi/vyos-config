Puppet::Type.newtype(:vy_ip_address) do
  @doc = "Manage an address for a network interface interface entry in vyatta"
  
  ensurable do
    desc "Valid values are present and absent."
    defaultto :present
  end

  newparam(:name,:namevar=>true) do
    desc "Interface spec/IPv4 or IPv6 address/network mask. Can be also 'dhcp' or 'dhcpv6'"
  end

  newparam(:address) do
    desc "IPv4 or IPv6 address/network mask. Defaults to name if not set"

    munge do |value|
      if value.empty? and resource[:name] =~
          /^(((eth\d+)|(eth\d+:\d+)|(lo\d*))\/)?((dhcp)|(dhcpv6)|(.+))$/
        $6
      else
        value
      end
    end

    defaultto ''

  end

  newparam(:interface) do
    desc "Interface name to set the address on. Defaults to name if not set and it's auto-required"

    munge do |value|
      if value.empty? and resource[:name] =~
          /^((eth\d+)|(eth\d+:\d+)|(lo\d*))\/((dhcp)|(dhcpv6)|(.+))$/
        $1
      else
        value
      end
    end

    defaultto ''
  end

  autorequire(:vy_interface) do
    autos = []

    if (obj = parameter(:interface)) and (if_name = obj.value)
      autos << if_name
    end

    autos
  end


  newparam(:description) do
    desc "Description of interface. Not stored on system but maybe in DNS"
  end
  
  newparam(:dns_names) do
    desc "DNS name that resolves to this address. Can be an array of names in which case the first is the name and the rest are aliases. Inherited from parent interface"
  end

  validate do
    val = self[:address]
    valid = true

    valid_values = %w(dhcp dhcpv6)
    unless valid_values.include? val.to_s
      if val =~ /^([^\/]+)\/(\d+)$/
        valid = begin
          IPAddr.new($1).to_s
        rescue
          nil
        end
      else
        valid = false
      end
    end
    self.fail "Invalid value for address #{val}" unless valid

    val = self[:interface]
    self.fail "Wrong interface specified #{val}" if val.empty?
  end

end
