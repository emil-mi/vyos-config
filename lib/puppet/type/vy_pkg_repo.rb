Puppet::Type.newtype(:vy_pkg_repo) do
  @doc = "Manage a debian package repository entry in vyatta"
  
  ensurable

  newparam :name do
    desc "Name of repository"
    isnamevar
  end

  newproperty(:components,:array_matching=>:all) do
    desc "Repository component names"
    
    def insync?(is)
	return false unless is.is_a? Array
	return false unless is.length == self.should.length
	return (is.sort == self.should.sort or is.sort == self.should.sort.map(&:to_s))
    end

    isrequired
  end

  newparam :description do
    desc "Repository description"
  end

  newproperty :distribution do
    desc "Distribution name"

    isrequired
  end

  newproperty :password do
    desc "Repository password"
  end

  newproperty :url do
    desc "Repository URL"
    
    validate do |value|
      require 'uri'
      raise ArgumentError, "url #{value.inspect} must be valid " unless value =~ URI::regexp
    end

    isrequired
  end

  newproperty :username do
    desc "Repository username"
  end

  newparam :pub_key do
    desc "Repository public key URL or hash to import"
  end

  newparam :match_mode do
    desc "How to consider defined properties. Valid values are 'inclusive' or 'minimum'. Default value is 'inclusive'"

    newvalues :minimum,:inclusive
    defaultto :inclusive
  end

  validate do
    required_should = [:url, :distribution, :components]
    has_should = required_should.select { |prop| self[prop] }
    self.fail "You must specify #{required_should.join(" and ")} on this type" if has_should.length != required_should.length
  end
   
 end
