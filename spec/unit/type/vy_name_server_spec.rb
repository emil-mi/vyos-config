require 'spec_helper'
require 'puppet/provider/vy_name_server/vyatta'


describe Puppet::Type.type(:vy_name_server) do

  it "should test mandatory parameters" do
    lambda { Puppet::Type.type(:vy_name_server).new(:name => "ns1.core.local") }.should raise_error

    lambda { Puppet::Type.type(:vy_name_server).new(:name => "192.168.0.256") }.should raise_error
    lambda { Puppet::Type.type(:vy_name_server).new(:name => "2001::1::a") }.should raise_error

    lambda { Puppet::Type.type(:vy_name_server).new(:name => "192.168.0.1") }.should_not raise_error
    lambda { Puppet::Type.type(:vy_name_server).new(:name => "::1") }.should_not raise_error
    lambda { Puppet::Type.type(:vy_name_server).new(:name => "ns1", :address=>"192.168.0.1") }.should_not raise_error
  end

  it "should support :present as a value to :ensure" do
    Puppet::Type.type(:vy_name_server).new(:name => "192.168.0.1",
                                        :ensure => :present)
  end

  it "should support :absent as a value to :ensure" do
    Puppet::Type.type(:vy_name_server).new(:name => "192.168.0.1",
                                           :ensure => :absent)
  end

  it "should prefetch based on address not on name" do
    config_sample = <<EOF
set system name-server 192.168.0.1
set system name-server 192.168.0.128
EOF
    resource_instance = Puppet::Type.type(:vy_name_server).new(
                                          :name => "ns1",
                                          :address=>"192.168.0.1",
                                          :ensure => :present)
    provider_class = Puppet::Type.type(:vy_name_server).provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    provider_class.prefetch( {resource_instance[:name] => resource_instance })

    resource_instance.provider.should be_a(VyattaConfigProvider)
    resource_instance[:ensure].should eq(:present)
    resource_instance.provider.exists?.should be_true
  end

  it "should return exising nameservers" do
    config_sample = <<EOF
set system name-server 192.168.0.1
set system name-server 192.168.0.128
EOF

    resource_class = Puppet::Type.type(:vy_name_server)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    resource_class.instances.count.should eq(2)

  end

end


