Puppet::Type.newtype(:vy_ntp_server) do
  @doc = "Manage an NTP server entry in vyatta"
  
  ensurable do
    desc "Valid values are present, absent and disabled."

    newvalues(:present,:absent,:disabled)

    validate do |val|
      valid_values = %w(present absent disabled)
      self.fail "Valid values for ensure are #{valid_values.join(' ')} not #{val.inspect}" unless
          valid_values.include? val.to_s
    end

    defaultto :present

    def retrieve
      if provider.exists?
        provider.ensure
      else
        return :absent
      end
    end

  end

  newparam(:name,:namevar=>true) do
    desc "IP address/DNS of NTP server"
  end

  newparam(:address) do
    desc "IP address/DNS of NTP server equal to name if missing"

    munge do |value|
      if value==:absent
        resource[:name]
      else
        value
      end
    end

    defaultto :absent
  end

  newproperty(:dynamic) do
    desc "Allow server to be configured even if not reachable"
  end

  newproperty(:preempt) do
    desc "Specifies the association as preemptable rather than persistent"
  end

  newproperty(:prefer) do
    desc "Marks the server as preferred"
  end
end