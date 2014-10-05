require 'spec_helper'
require 'puppet/provider/vy_timezone/vyatta'


describe Puppet::Type.type(:vy_timezone) do

  describe Puppet::Type.type(:vy_timezone).provider(:vyatta) do
    before do
      @provider_class = Puppet::Type.type(:vy_timezone).provider(:vyatta)
    end
    it "loads all items when instances is called" do
      config_sample = <<EOF
set system time-zone 'Europe/Bucharest'
EOF
      @provider_class.stubs(:config_statements).returns config_sample.split("\n")
      @provider_class.instances.count.should eq(1)
    end
  end

  it "should create the delete commands" do
    config_sample = <<EOF
set system time-zone 'Europe/Bucharest'
EOF
    @provider_class = Puppet::Type.type(:vy_timezone).defaultprovider
    @provider_class.stubs(:config_statements).returns config_sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_timezone).new(:name => "Europe/Bucharest",
                                                             :ensure => :absent)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    @resource_instance.provider.expects(:exec_config_commands).with(equals(['delete system time-zone']))

    @resource_instance.provider.destroy
    @resource_instance.provider.flush
  end

  it "should create the 'create statements" do
    config_sample = <<EOF
set system time-zone 'Europe/Bucharest'
EOF
    @provider_class = Puppet::Type.type(:vy_timezone).defaultprovider
    @provider_class.stubs(:config_statements).returns config_sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_timezone).new(:name => "Europe/Dublin",
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    expected_statements = [
        "set system time-zone Europe/Dublin",
      ]
    @resource_instance.provider.expects(:exec_config_commands).with(equals(expected_statements))

    @resource_instance.provider.create
    @resource_instance.provider.flush
  end

  it "should return existing time-zone" do
    config_sample = <<EOF
set system time-zone 'Europe/Bucharest'
EOF
    resource_class = Puppet::Type.type(:vy_timezone)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns config_sample.split("\n")

    instances = resource_class.instances
    instances.count.should eq(1)
  end

end


