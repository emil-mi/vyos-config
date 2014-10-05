require 'spec_helper'
require 'puppet/provider/vy_name_server/vyatta'


describe Puppet::Type.type(:vy_ip_address) do

  it "should test mandatory parameters" do
    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "192.168.0.1") }.should raise_error

    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "eth0/192.168.0.1") }.should raise_error
    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "eth0/192.168.0/24") }.should raise_error
    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "eth0/2001::1::2/24") }.should raise_error

    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "eth0/192.168.0.1/24") }.should_not raise_error
    lambda { Puppet::Type.type(:vy_ip_address).new(:name => "eth0/::1/24") }.should_not raise_error

    lambda { Puppet::Type.type(:vy_ip_address).new(
        :name => "192.168.0.1/24",
        :interface => "eth0") }.should_not raise_error
    lambda { Puppet::Type.type(:vy_ip_address).new(
        :name => "test",
        :address => "192.168.0.1/24",
        :interface => "eth0") }.should_not raise_error
  end

  it "should support :present as a value to :ensure" do
    Puppet::Type.type(:vy_ip_address).new(:name => "eth0/192.168.0.1/24",
                                          :ensure => :present)
  end

  it "should support :absent as a value to :ensure" do
    Puppet::Type.type(:vy_ip_address).new(:name => "eth0/192.168.0.1/24",
                                          :ensure => :absent)
  end

  it "should prefetch based on address not on name" do
    config_sample = <<EOF
set interfaces ethernet eth0 address 192.168.0.1/24
set interfaces ethernet eth0 address 192.168.1.1/24
EOF
    resource_instance = Puppet::Type.type(:vy_ip_address).new(
                                          :name => "addr1",
                                          :interface=>"eth0",
                                          :address=>"192.168.0.1/24",
                                          :ensure => :present)
    provider_class = Puppet::Type.type(:vy_ip_address).provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    provider_class.prefetch( {resource_instance[:name] => resource_instance })

    resource_instance.provider.should be_a(VyattaConfigProvider)
    resource_instance[:ensure].should eq(:present)
    resource_instance.provider.exists?.should be_true
  end

  it "should return exising interfaces" do
    config_sample = <<EOF
set interfaces ethernet eth0 address 192.168.0.1/24
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces loopback lo address ::1/128
EOF

    resource_class = Puppet::Type.type(:vy_ip_address)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    instances = resource_class.instances
    instances.count.should eq(3)
    instances = instances.map { |i| i.name }
    instances.each { |i|
      puts i
      %w(eth0/192.168.0.1/24 eth1/192.168.1.1/24 lo/::1/128).include?(i).should be_true
    }
  end

end


