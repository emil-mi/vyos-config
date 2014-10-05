
Puppet::Type.newtype(:vy_user) do
  @doc = "Manage a user entry in vyatta"
  
  ensurable do
    desc "Valid values are 'admin','operator','disabled' and 'absent'"

    newvalues(:admin,:operator,:disabled,:absent)

    validate do |val|
      valid_values = %w(admin operator disabled absent)
      self.fail "Valid values for ensure are #{valid_values.join(' ')} not #{val.inspect}" unless
          valid_values.include? val.to_s
    end

    defaultto {
      nil
    }

    def retrieve
      if provider.exists?
        provider.ensure
      else
        return :absent
      end
    end
  end

  newparam(:name,:namevar=>true) do
    desc "The username"
  end

  newproperty(:password) do
    desc "Password to set. It will be encrypted using 'encryption'. If emtpy user has no password"

    defaultto {
      nil
    }

    def make_salt(len)
      chars =  [('0'..'9'),('a'..'z'),('A'..'Z'),'.','/'].map{|i| Array(i)}.flatten
      return (0...len).map{ chars[rand(chars.length)] }.join
    end

    unmunge do |pwd|
      return '' if pwd==''
      case resource[:encryption].to_s
        when /^md5(\/(.{4,12}))?$/
          salt=$2?$2:make_salt(12)
          return pwd.crypt("$1$"+salt)
        when /^des(\/(.{2}))?$/
          salt=$2?$2:make_salt(2)
          return pwd.crypt(salt)
        when /^sha-?256(\/(.{4,16}))?$/
          salt=$2?$2:make_salt(16)
          return pwd.crypt("$5$"+salt)
        when /^sha-?512(\/(.{4,16}))?$/
          salt=$2?$2:make_salt(16)
          return pwd.crypt("$6$"+salt)
        when 'none'
          return pwd
        else
          self.fail "Valid values for encryption are 'md5','des','sha-256','sha-512' or 'none' not #{resource[:encryption]}"
      end
    end
  end

  newproperty(:full_name) do
    desc "Full name"
  end

  newproperty(:home) do
    desc "Home directory"
  end

  newproperty(:encryption) do
    desc "Encryption method for the password. Can be 'md5'/salt or 'sha-256'/salt or 'sha-512'/salt or 'none' in which case the password is set as is allowing you to specify the encrypted password yourself. salt is not required and will be generated"
    validate do |val|
      case val.to_s
        when /^md5(\/(.{4,12}))?$/
        when /^des(\/(.{2}))?$/
        when /^sha-?256(\/(.{4,16}))?$/
        when /^sha-?512(\/(.{4,16}))?$/
        when 'none'
        else
          self.fail "Valid values for encryption are 'md5','sha-256','sha-512' or 'none' not #{val}"
      end
    end
    defaultto 'md5'

    def insync?(is) #it is actually a parameter
      true
    end
  end

  newproperty(:group,:array_matching=>:all) do
    desc "group or array of groups the user must be member of"

  end

  autorequire(:group) do
    autos = []

    if (obj = parameter(:group)) and (groups = obj.value)
      groups = groups.split(',') if groups.is_a? String
      autos += groups
    end

    autos
  end
  
  newparam(:group_membership) do
    desc "Wheter group membership must be 'mimimum' (the user is allowed to be member of other groups than the ones specified here) or 'inclusive' (the user must be a member of the groups specified here and nothing more). Groups are auto-required"

    validate do |val|
      self.fail "Valid values for encryption are 'minimum' or 'inclusive' not #{val}" if
          val.to_s!='minimum' and val.to_s!='inclusive'
    end

    newvalues(:inclusive,:minimum)

    defaultto :inclusive
  end
 end
