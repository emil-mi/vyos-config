require 'spec_helper'
require 'puppet/provider/vy_pkg_repo/vyatta'


describe Puppet::Type.type(:vy_pkg_repo) do

  Config_Sample = <<EOF
set system package repository community components 'main'
set system package repository community distribution 'stable'
set system package repository community url 'http://packages.vyatta.com/vyatta'
set system package repository debian components 'main contrib non-free'
set system package repository debian distribution 'squeeze'
set system package repository debian url 'http://ftp.debian.org/debian'
EOF
  Config_Sample_Empty_Password = <<EOF
set system package repository community components 'main'
set system package repository community distribution 'stable'
set system package repository community url 'http://packages.vyatta.com/vyatta'
set system package repository debian components 'main contrib non-free'
set system package repository debian username ''
set system package repository debian password ''
set system package repository debian distribution 'squeeze'
set system package repository debian url 'http://ftp.debian.org/debian'
EOF
  Config_Sample_Some_Password = <<EOF
set system package repository community components 'main'
set system package repository community distribution 'stable'
set system package repository community url 'http://packages.vyatta.com/vyatta'
set system package repository debian components 'main contrib non-free'
set system package repository debian username ''
set system package repository debian password 'test'
set system package repository debian distribution 'squeeze'
set system package repository debian url 'http://ftp.debian.org/debian'
EOF

  describe Puppet::Type.type(:vy_pkg_repo).provider(:vyatta) do
    before do
      @provider_class = Puppet::Type.type(:vy_pkg_repo).provider(:vyatta)
    end
    it "loads all items when instances is called" do
      @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
      @provider_class.instances.count.should eq(2)
    end
  end

  it "should test mandatory parameters" do
    lambda { Puppet::Type.type(:vy_pkg_repo).new(:name => "debian") }.should raise_error

    lambda { Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                 :url => 'http://ftp.debian.org/debian',
                                                 :distribution => 'squeeze',
                                                 :components => ['main','contrib','non-free'])
    }.should_not raise_error
  end
  it "should accept both strings and arrays for 'components'" do
    lambda { Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                 :url => 'http://ftp.debian.org/debian',
                                                 :distribution => 'squeeze',
                                                 :components => ['main','contrib','non-free'])
    }.should_not raise_error

    lambda { Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                 :url => 'http://ftp.debian.org/debian',
                                                 :distribution => 'squeeze',
                                                 :components => 'main')
    }.should_not raise_error
  end

  it "should support :present as a value to :ensure" do
    Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                        :url => 'http://ftp.debian.org/debian',
                                        :distribution => 'squeeze',
                                        :components => 'main',
                                        :ensure => :present)
  end

  it "should support :absent as a value to :ensure" do
    Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                        :url => 'http://ftp.debian.org/debian',
                                        :distribution => 'squeeze',
                                        :components => 'main',
                                        :ensure => :absent)
  end

  it "should detect it exists" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                        :url => 'http://ftp.debian.org/debian',
                                        :distribution => 'squeeze',
                                        :components => ['main','contrib', 'non-free'],
                                        :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })
    @resource_instance.provider.should be_a(VyattaConfigProvider)
    @resource_instance[:ensure].should eq(:present)
    @resource_instance.provider.exists?.should be_true
  end

  it "should detect it exists if :match_mode=>:minimum" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.org/debian',
                                                             :distribution => 'squeeze',
                                                             :components => 'main',
                                                             :match_mode=>:minimum,
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })
    @resource_instance.provider.should be_a(VyattaConfigProvider)
    @resource_instance[:ensure].should eq(:present)
    @resource_instance.provider.exists?.should be_true
  end

  it "should detect it doesn't exist" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.ro/debian',
                                                             :distribution => 'squeeze',
                                                             :components => 'main',
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })
    @resource_instance.provider.should be_a(VyattaConfigProvider)
    @resource_instance[:ensure].should eq(:present)
    @resource_instance.provider.exists?.should be_false
  end

  it "should detect it exists with empty password (default for repo_spec)" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample_Empty_Password.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.org/debian',
                                                             :distribution => 'squeeze',
                                                             :components => ['main','contrib', 'non-free'],
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })
    @resource_instance.provider.should be_a(VyattaConfigProvider)
    @resource_instance[:ensure].should eq(:present)
    @resource_instance.provider.exists?.should be_true
  end

  it "should detect it does not exists with password set " do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample_Some_Password.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.org/debian',
                                                             :distribution => 'squeeze',
                                                             :password => 'test',
                                                             :components => ['main','contrib', 'non-free'],
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })
    @resource_instance.provider.should be_a(VyattaConfigProvider)
    @resource_instance[:ensure].should eq(:present)
    @resource_instance.provider.exists?.should be_true
  end

  it "should create the delete commands" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.org/debian',
                                                             :distribution => 'squeeze',
                                                             :components => ['main','contrib', 'non-free'],
                                                             :ensure => :absent)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    @resource_instance.provider.expects(:exec_config_commands).with(equals(['delete system package repository debian']))

    @resource_instance.provider.destroy
    @resource_instance.provider.flush
  end

  it "should create the 'create statements" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "puppet",
                                                             :url => 'http://www.puppet.org/puppet',
                                                             :distribution => 'puppet',
                                                             :components => ['main','contrib'],
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    expected_statements = [
        "set system package repository puppet components 'contrib main'",
        "set system package repository puppet distribution puppet",
        "set system package repository puppet url http://www.puppet.org/puppet"
    ]
    @resource_instance.provider.expects(:exec_config_commands).with(equals(expected_statements))

    @resource_instance.provider.create
    @resource_instance.provider.flush
  end

  it "should perform 'update statements' when match_mode is :inclusive" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://ftp.debian.org/debian',
                                                             :distribution => 'squeeze',
                                                             :components => ['main','contrib'],
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    expected_statements = [
        "set system package repository debian components 'contrib main'"
    ]

    @resource_instance.provider.expects(:exec_config_commands).with(equals(expected_statements))

    @resource_instance.provider.create
    @resource_instance.provider.flush
  end

  it "should perform 'update statements' when match_mode is :minimum" do
    @provider_class = Puppet::Type.type(:vy_pkg_repo).defaultprovider
    @provider_class.stubs(:config_statements).returns Config_Sample.split("\n")
    @resource_instance = Puppet::Type.type(:vy_pkg_repo).new(:name => "debian",
                                                             :url => 'http://www.debian.org/debian',
                                                             :distribution => 'lenny',
                                                             :components => 'other',
                                                             :match_mode=>:minimum,
                                                             :ensure => :present)

    @provider_class.prefetch( {@resource_instance[:name] => @resource_instance })

    expected_statements = [
        "set system package repository debian components 'contrib main non-free other'",
        "set system package repository debian distribution lenny",
        "set system package repository debian url http://www.debian.org/debian",
    ]

    @resource_instance.provider.expects(:exec_config_commands).with(equals(expected_statements))

    @resource_instance.provider.create
    @resource_instance.provider.flush
  end

  it "should return existing repositories" do
    resource_class = Puppet::Type.type(:vy_pkg_repo)

    provider_class = resource_class.provider(:vyatta)
    provider_class.stubs(:config_statements).returns Config_Sample.split("\n")

    instances = resource_class.instances
    instances.count.should eq(2)
    instances.map { |i|
      i[:ensure]!=:absent
    }.all?.should be_true
  end

end


