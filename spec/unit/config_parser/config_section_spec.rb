require 'spec_helper'
require 'puppet/provider/util/VyattaConfigFile'

def section_tree_valid(section)
  section.root.select { |s|
    not (s.root? or s.parent.subsections[s.name].equal?(s))
  }.empty?
end

describe VyattaConfigSection do

  describe :to_s do
    it 'should be the empty string for root' do
      VyattaConfigFile.parse("").to_s.should eq("")
    end

    it 'should return a non empty string otherwise' do
      sample_config = <<EOF
      set section1
      set section2
      set section3
EOF
      VyattaConfigFile.parse(sample_config).to_s.should_not be_empty
    end
  end

  describe :select do

    it 'should return all nodes if no block is given' do
      sample_config = <<EOF
      set section1
      set section2
      set section3
EOF
      VyattaConfigFile.parse(sample_config).select.count.should eq(4)
    end

    it 'should execute block for each section' do
      sample_config = <<EOF
      set section1
      set section2
      set section3
EOF
      num_calls=0
      VyattaConfigFile.parse(sample_config).select { |s|
        num_calls+=1
      }
      num_calls.should eq(4)
    end

    it 'should return only sections for which block is true' do
      sample_config = <<EOF
      set section1
      set section2
      set section3
EOF
      VyattaConfigFile.parse(sample_config).select { |s|
        s.name =~ /section[23]/
      }.count.should eq(2)
    end
  end

  describe :section_created_hook do
    it 'should be called for each new section when parsing' do

      class VyattaConfigFileNew < VyattaConfigFile
        class << self
          attr_accessor :count
        end
        def section_created_hook(sender,new_section)
          self.class.count += 1
        end
      end

      sample_config = <<EOF
set section1
set section2
set section3
EOF
      VyattaConfigFileNew.count=0
      VyattaConfigFileNew.parse(sample_config)
      VyattaConfigFileNew.count.should eq(3)
    end
  end

  describe :to_hash do
    it 'should be convertible to an empty hash if empty' do
      s=VyattaConfigSection.new("lvl1 lvl2 'lvl 3'")
      s.should be_empty
      s.to_hash.should be_empty
    end

    it 'should be convertible to a hash' do
      s=VyattaConfigSection.new("lvl1 lvl2 'lvl 3'").root
      s.to_hash.should eq({'lvl1'=>{'lvl2'=>{'lvl 3'=>{}}}})
    end
  end

  describe :superset? do
    it 'should validate its arguments' do
      expect { VyattaConfigSection.new("lvl1").superset? nil }.to raise_error(ArgumentError)
    end

    it 'should be a superset of an empty section' do
      VyattaConfigSection.new("lvl1 lvl2").parent.superset?(VyattaConfigSection.new("lvl1")).should be_true
    end

    it 'should be a superset of itself' do
      s = VyattaConfigSection.new("lvl1")
      s.superset?(s).should be_true
    end

    it 'should be a superset of itself' do
      s = VyattaConfigSection.new("lvl1")
      s.superset?(s).should be_true

      section_tree_valid(s).should be_true
    end

    it 'should not be a superset of a different set' do
      VyattaConfigSection.new("lvl1").superset?( VyattaConfigSection.new("lvl2") ).should be_false
    end

    it 'should check its subsections' do
      FirstSection = <<EOF
set repository community components 'main'
set repository community distribution 'stable'
set repository community url 'http://packages.vyatta.com/vyatta'
EOF
      SecondSection = <<EOF
set repository community components 'main'
set repository community distribution 'stable'
set repository community distribution 'unstable'
set repository community url 'http://packages.vyatta.com/vyatta'
EOF
      section1 = VyattaConfigFile.parse(FirstSection).select { |s|
        s.name == 'repository'
      }.first
      section2 = VyattaConfigFile.parse(SecondSection).select { |s|
        s.name == 'repository'
      }.first
      section2.superset?(section1).should be_true
      section1.superset?(section2).should be_false

      section_tree_valid(section1).should be_true
      section_tree_valid(section2).should be_true
    end
  end

  describe :track_changes do
    it "should track inserts" do
      root=VyattaConfigSection.new()
      changes = root.track_changes {
        s1 = root << 'lvl1'
        s2 = s1 << 'lvl2'
        s2.full_path.should eq('lvl1 lvl2')
      }

      changes.count.should eq(2)
      changes.each_with_index { |(c,s),i|
        if i==0
          c.should eq(:add)
          s.name.should eq('lvl1')
        elsif i==1
          c.should eq(:add)
          s.name.should eq('lvl2')
        end
      }

      VyattaConfigSection.new().track_changes { |s|
        s << 'lvl1 lvl2 lvl3'
      }.count.should eq(1)

      VyattaConfigSection.new().track_changes { |s|
        s << 'lvl1' << 'lvl2' << 'lvl3'
      }.count.should eq(3)

      config_commands = <<EOF
set l1 l2 'le 1'
set l1 l2 'le 2'
set l1-1 l2 'le 2'
EOF
      VyattaConfigSection.new("l0").track_changes { |s|
        s << VyattaConfigFile.parse(config_commands)
      }.count.should eq(2)
    end

    it "should track deletes" do
      config_commands = <<EOF
set l1 l2 'le 1'
set l1 l2 'le 2'
set l0 l1 l2 l3
EOF
      changes=VyattaConfigFile.parse(config_commands).track_changes { |r|
        r.delete r['l0']
      }
      changes.count.should eq(1)
      changes.each_with_index { |(c,s),i|
        c.should eq(:delete)
        s.name.should eq('l0')
      }
    end
  end

  describe :root do
    it "should return a section's root" do
      sample_config = <<EOF
      set section1
      set section2
      set section3
EOF
      section1 = VyattaConfigFile.parse(sample_config).select { |s|
        s.name == 'section1'
      }.first
      section1.root?.should be(false)
      section1.root.root?.should be(true)
    end
  end

  describe :initialize do
    it 'should be constructed from nil and be root' do
      VyattaConfigSection.new(nil).should be_root
    end

    it 'should be constructed from an empty string and be root' do
      s=VyattaConfigSection.new("").should be_root
    end

    it 'should be constructed from a full section name' do
      s=VyattaConfigSection.new("lvl1 lvl2 'lvl 3'")
      s.name.should eq('lvl 3')
      s.parent.name.should eq('lvl2')
      s.parent.parent.name.should eq('lvl1')
      s.parent.parent.parent.should be_root
    end

    it 'should construct subsections specified in hash' do
      s=VyattaConfigSection.new( :name=>"lvl1", :hash=> { 'lvl2' => { 'lvl 3'=>{} } } )
      s.select { |s|
        s.name=='lvl 3'
      }.first.full_path=="lvl1 lvl2 'lvl 3'"

      section_tree_valid(s).should be_true
      end
  end

  describe :<< do
    it 'should add sub-sections specified by name' do
      s=VyattaConfigSection.new("lvl1")
      (s << "lvl2").full_path.should eq("lvl1 lvl2")

      section_tree_valid(s).should be_true
    end

    it 'should add sub-sections specified by path' do
      section=VyattaConfigSection.new("lvl1")
      section << "lvl2 'lvl 3'"

      section.select { |s|
        s.empty?
      }.first.full_path.should eq("lvl1 lvl2 'lvl 3'")

      section_tree_valid(section).should be_true
    end

    it 'should add copy of sub-sections' do
      section1=VyattaConfigSection.new("lvl1")

      class << section1.root
        include RSpec::Matchers
        def section_created_hook(sender,new_section)
          sender.name.should eq("lvl1")
          new_section.name.should eq("lvl 3")
          new_section
        end
      end

      section2=VyattaConfigSection.new("lvl2 'lvl 3'")

      just_added=section1 << section2
      section_tree_valid(section1).should be_true

      just_added.full_path.should eq("lvl1 'lvl 3'")
      just_added.should_not be_equal(section2)

      section1=VyattaConfigSection.new("lvl1")
      just_added=section1 << section2.root
      section_tree_valid(section1).should be_true

      just_added.full_path.should eq("lvl1 lvl2")

      section1.select { |s|
        s.empty?
      }.first.full_path.should eq("lvl1 lvl2 'lvl 3'")

      section1=VyattaConfigSection.new("lvl1")
      just_added=section1 << section2.root.subsections.first[1]
      section_tree_valid(section1).should be_true

      just_added.full_path.should eq("lvl1 lvl2")

      section1.select { |s|
        s.empty?
      }.first.full_path.should eq("lvl1 lvl2 'lvl 3'")

      section1=VyattaConfigSection.new
      section2=VyattaConfigSection.new("lvl2 'lvl 3'")
      just_added=section1 << section2.root
      section_tree_valid(section1).should be_true

      section1.select { |s|
        s.empty?
      }.first.full_path.should eq("lvl2 'lvl 3'")
    end
  end

  describe :- do
    it "should obey the mathematical definition of set difference" do
      empty_root = VyattaConfigSection.new
      non_empty_root = VyattaConfigSection.new
      non_empty_root << 'lvl1'

      empty_section = VyattaConfigSection.new('lvl1')

      section = VyattaConfigSection.new('lvl1')
      section << 'lvl2-1' << 'lvl3'
      section << 'lvl2-2'

      sub_section = VyattaConfigSection.new('lvl1')
      sub_section << 'lvl2-1'

      distinct_section = VyattaConfigSection.new('lvl1')
      distinct_section << 'lvl2-3'

      unrelated_section = VyattaConfigSection.new('un-related')
      unrelated_section << 'lvl2'

      (section-section).should be_empty
      (empty_section-section).should be_empty
      (section-empty_section).map {|s| s.name }.sort.should eq(['lvl2-1','lvl2-2'])

      (section-sub_section).map {|s| s.name }.sort.should eq(['lvl2-2','lvl3'])

      (sub_section-section).should be_empty
      section.superset?(sub_section).should be_true

      (section-distinct_section).map {|s| s.name }.sort.should eq(['lvl2-1','lvl2-2'])
      (distinct_section-section).map {|s| s.name }.sort.should eq(['lvl2-3'])

      (section-unrelated_section).should eq([section])

      (empty_root-non_empty_root).should be_empty
      (non_empty_root-empty_root).map {|s| s.name }.sort.should eq(['lvl1'])
    end
  end
end
