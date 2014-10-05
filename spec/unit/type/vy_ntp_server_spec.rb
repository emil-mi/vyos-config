require 'spec_helper'
require 'puppet/provider/vy_ntp_server/vyatta'


describe Puppet::Type.type(:vy_ntp_server) do

  it "should support :present as a value to :ensure" do
    Puppet::Type.type(:vy_ntp_server).new(:name => "192.168.0.1",
                                        :ensure => :present)
  end

  it "should support :absent as a value to :ensure" do
    Puppet::Type.type(:vy_ntp_server).new(:name => "192.168.0.1",
                                           :ensure => :absent)
  end

  it "should support :disabled as a value to :ensure" do
    Puppet::Type.type(:vy_ntp_server).new(:name => "192.168.0.1",
                                          :ensure => :disabled)
  end

  it "should prefetch based on address not on name" do
    config_sample = <<EOF
set system ntp server '0.pool.ntp.org'
set system ntp server '1.pool.ntp.org'
set system ntp server '2.pool.ntp.org'
EOF
    resource_instance = Puppet::Type.type(:vy_ntp_server).new(
                                          :name => "ts1",
                                          :address=>"0.pool.ntp.org",
                                          :ensure => :present)
    provider_class = Puppet::Type.type(:vy_ntp_server).provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    provider_class.prefetch( {resource_instance[:name] => resource_instance })

    resource_instance.provider.should be_a(VyattaConfigProvider)
    resource_instance[:ensure].should eq(:present)
    resource_instance.provider.exists?.should be_true
  end

  it "should return exising nameservers" do
    config_sample = <<EOF
set system ntp server '0.pool.ntp.org'
set system ntp server '1.pool.ntp.org'
set system ntp server '2.pool.ntp.org'
EOF

    resource_class = Puppet::Type.type(:vy_ntp_server)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    instances = resource_class.instances
    instances.count.should eq(3)

  end

end


