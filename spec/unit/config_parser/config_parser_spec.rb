require 'spec_helper'
require 'puppet/provider/util/VyattaConfigFile'

describe VyattaConfigFile do
  describe VyattaConfigFile.method(:parse) do

    it 'should accept nil' do
      VyattaConfigFile.parse(nil).should be_nil
    end

    it 'should return the root section' do
      empty_config = ""
      VyattaConfigFile.parse(empty_config).should be_root
      with_spaces_config = "set section data 'some contents'"
      VyattaConfigFile.parse(with_spaces_config).should be_root
    end

    it 'should parse empty configuration' do
      empty_config = ""
      cfg = VyattaConfigFile.parse(empty_config)
      cfg.should be_a_kind_of VyattaConfigFile
      cfg.should be_empty
    end

    it 'should parse simple configuration' do
      simple_config = "set section"
      VyattaConfigFile.parse(simple_config).should be_a_kind_of VyattaConfigFile
    end

    it 'should parse quoted strings' do
      with_spaces_config = "set section data 'some contents'"
      VyattaConfigFile.parse(with_spaces_config).should be_a_kind_of VyattaConfigFile
    end

    it 'should parse configuration with empty values' do
      empty_config = "set username ''"
      cfg = VyattaConfigFile.parse(empty_config)
      cfg.leaves.first.name.should be_empty
    end

    it 'should parse sample config' do
      config_sample = <<EOF
set interfaces ethernet eth0 address 'dhcp'
set interfaces ethernet eth0 address '2001::/48'
set interfaces ethernet eth0 description 'Core interface'
set interfaces ethernet eth0 duplex 'auto'
set interfaces ethernet eth0 hw-id '00:50:56:9a:00:60'
set interfaces ethernet eth0 smp_affinity 'auto'
set interfaces ethernet eth0 speed 'auto'

set interfaces loopback 'lo'

set interfaces ethernet eth1 address 192.168.0.1/24
set interfaces ethernet eth1 duplex 'auto'

set interfaces pseudo-ethernet peth0 address '10.10.0.1/24'
set interfaces pseudo-ethernet peth0 address '10.10.1.1/24'
set interfaces pseudo-ethernet peth0 address '2001:67c:16d8::/48'
set interfaces pseudo-ethernet peth0 description 'Core interface'
set interfaces pseudo-ethernet peth0 'disable'
set interfaces pseudo-ethernet peth0 link 'eth0'

set service ssh
set system 'config-management'
set system domain-name 'management.local'
set system host-name 'template-vyatta'

set system login user gogou authentication encrypted-password '$1$PNjLa.IP$MG2OzPbwiGRRpN23/x.es1'
set system login user gogou full-name 'Gogu Duru'
set system login user gogou group 'ntp'
set system login user gogou group 'src'
set system login user gogou home-directory '/home/gogu'
set system login user gogou level 'admin'

set system login user vyatta authentication encrypted-password '$1$PNjLa.IP$MG2OzPbwiGRRpN23/x.es1'
set system login user vyatta level 'admin'
set system ntp server '0.ntp.core.local'
set system ntp server '1.ntp.core.local'
set system time-zone 'Europe/Berlin'
set system package repository community components 'main'
set system package repository community distribution 'stable'
set system package repository community url 'http://packages.vyatta.com/vyatta'
set system package repository debian components 'main contrib non-free'
set system package repository debian distribution 'squeeze'
set system package repository debian url 'http://ftp.debian.org/debian'
EOF
      s=VyattaConfigFile.parse(config_sample)
      s.should be_a_kind_of VyattaConfigFile
    end
  end

  it 'should be empty by default' do
    VyattaConfigFile.new.should be_empty
  end

  it 'should be a root by default' do
    VyattaConfigFile.new.root?.should be(true)
  end

  it 'full_path should be empty by default' do
    VyattaConfigFile.new.full_path.should be_empty
  end

  it 'should be convertible to empty string string by default' do
    VyattaConfigFile.new.to_s.should be_empty
  end

  it 'should be have an zero arity constructor' do
    expect { VyattaConfigFile.new }.to_not raise_error
  end
end