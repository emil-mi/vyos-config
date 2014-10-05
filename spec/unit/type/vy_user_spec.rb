require 'spec_helper'
require 'puppet/provider/vy_user/vyatta'


describe Puppet::Type.type(:vy_user) do

  it "should support :admin as a value to :ensure" do
    lambda {
      Puppet::Type.type(:vy_user).new(:name => "gogu",
                                      :ensure => :admin)
    }.should_not raise_error
  end

  it "should support :operator as a value to :ensure" do
    lambda {
      Puppet::Type.type(:vy_user).new(:name => "gogu",
                                             :ensure => :operator)
    }.should_not raise_error
  end

  it "should support :disabled as a value to :ensure" do
    lambda {
      Puppet::Type.type(:vy_user).new(:name => "gogu",
                                      :ensure => :disabled)
    }.should_not raise_error
  end

  it "should support :absent as a value to :ensure" do
    lambda {
      Puppet::Type.type(:vy_user).new(:name => "gogu",
                                      :ensure => :absent)
    }.should_not raise_error
  end

  it "should not support other values for :ensure" do
    lambda {
      Puppet::Type.type(:vy_user).new(:name => "gogu",
                                      :ensure => :present)
    }.should raise_error
  end

  it "should support :des as a value to :encryption" do
    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                    :ensure => :operator,
                                    :password => 'test',
                                    :encryption => 'des')
    res[:password].should_not be_empty
    res[:password].should_not eq('test')

    lambda {
      res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                          :ensure => :operator,
                                          :password => 'test',
                                          :encryption => 'des/a')
    }.should raise_error

    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                        :ensure => :operator,
                                        :password => 'test',
                                        :encryption => 'des/ab')
    res[:password].should eq('test'.crypt('ab'))
  end

  it "should support :md5 as a value to :encryption" do
    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                        :ensure => :operator,
                                        :password => 'test',
                                        :encryption => 'md5')
    res[:password].should_not be_empty
    res[:password].should_not eq('test')

    lambda {
      res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                          :ensure => :operator,
                                          :password => 'test',
                                          :encryption => 'md5/a')
    }.should raise_error

    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                        :ensure => :operator,
                                        :password => 'test',
                                        :encryption => 'md5/PNjLa.IP')
    res[:password].should eq('test'.crypt('$1$PNjLa.IP'))
  end

  it "should support :none as a value to :encryption" do
    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                        :ensure => :operator,
                                        :password => 'test',
                                        :encryption => 'none')
    res[:password].should eq('test')
  end

  it "should autorequire groups" do
    res=Puppet::Type.type(:vy_user).new(:name => 'gogu',
                                        :ensure => :operator,
                                        :password => 'test',
                                        :encryption => 'none',
                                        :group => 'gdm')
    group = Puppet::Type.type(:group).new(:name=>'gdm')
    catalog = Puppet::Resource::Catalog.new :testing do |cat|
      cat.add_resource res
      cat.add_resource group
    end
    req = res.autorequire.map { |e| e.source.ref }

    req.include?(group.ref).should be_true
  end

  it "should return existing users" do
    config_sample = <<EOF
set system login user vyatta authentication encrypted-password '$1$4kaP5.lA$BlX8CShHH91JwaVSCPaqF1'
set system login user vyatta level 'admin'
set system login user gogu authentication encrypted-password '$1$4kaP5.lA$BlX8CShHH91JwaVSCPaqF1'
set system login user gogu level 'operator'
EOF
    resource_class = Puppet::Type.type(:vy_user)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    instances = resource_class.instances
    instances.count.should eq(2)
    instances.map { |i|
      "#{i[:name]}/#{i[:ensure]}"
    }.sort.should eq(['gogu/operator','vyatta/admin'])
  end

end


