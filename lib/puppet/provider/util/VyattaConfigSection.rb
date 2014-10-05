require File.dirname(__FILE__) + '/orderedhash'

class VyattaConfigSection
  attr_reader :subsections

  protected
  def subsections=(hash)
    @subsections = OrderedHash().merge!(hash)
  end

  def parent=(section)
    @parent = section
  end

  public
  attr_reader :name

  def initialize( settings={} )
    unless settings
      @subsections=OrderedHash()
      @name='[root]'
      @parent=self
      return
    end
    settings = {:path=>settings} if settings.is_a? String
    parent = settings[:parent]
    name = settings[:name]
    path = settings[:path]
    hash = settings[:hash]
    unless parent or name or path or hash
      @subsections=OrderedHash()
      @name='[root]'
      @parent=self
      return
    end
    raise ArgumentError,"path is not allowed with name" if path and name
    raise ArgumentError,"name or path must be specified" unless name or path
    raise ArgumentError,"path or name must be strings" if
        (path and not path.is_a? String) or (name and not name.is_a? String)
    path = quote(name.strip) if name
    path = path.strip

    raise ArgumentError,"name or path must not be an empty string (or just spaces) if parent is specified" if
      path.empty? and parent

    @subsections=OrderedHash()
    path_components = self.class.split_path(path)

    case path_components.size
      when 0 then
        @name='[root]'
        @parent=self
      when 1 then
        @name=path_components.first
        if parent
          @parent=parent
        else
          root = self.class.new({})
          @parent=root
          root.subsections[@name]=self
        end
      else
        root = self.class.new({})
        myself = root.create_section(path_components)
        if parent
          myself = root.subsections.first[1]
          @name = myself.name
          @parent = parent
          @subsections=myself.subsections
          @subsections.each { |n,v|
            v.parent = self
          }
        else
          @name = myself.name
          @parent = myself.parent
          @parent.subsections[@name]=self
        end
    end
    if hash
      raise ArgumentError,"hash must be a hash" unless hash.is_a?(Hash)
      hash.each { |n,val|
        @subsections[n] = self.class.new( :parent=>self,:name=>n, :hash=>val )
      }
    end
  end

  def <<(section)
    raise ArgumentError,"section must be not nil or empty" if not section or (section.is_a? String and section.empty?)
    if section.is_a? String
      section=self.class.new(:path => section, :parent => self)
      raise ArgumentError,"section named '#{section.name}' already exists in #{self}" if @subsections.key? section.name
      @subsections[section.name]=section
      hook=section_created_hook(self,section)
      section = hook if hook.is_a? VyattaConfigSection
      return section
    else
      if section.root?
        ret=section.subsections.map { |n,s|
          self << s
        }
        if ret.count==1
          return ret.first
        else
          return ret
        end
      end
      raise ArgumentError,"section '#{section}' already exists in #{self}" if @subsections.key? section.name
      new_section=self.class.new(:name => section.name, :parent => self, :hash => section.to_hash)
      @subsections[new_section.name]=new_section
      hook=section_created_hook(self,new_section)
      new_section = hook if hook.is_a? VyattaConfigSection
      return new_section
    end
  end

  # @param [[String]] elements
  # @return [VyattaConfigSection]
  protected
  def create_section(elements)
    return self unless elements
    elements = [elements] unless elements.is_a?(Array)
    ret = elements.reduce(self) { |section,element|
      section.subsections[element] ||= self.class.new( :parent=>section,:name=>element )
      section.subsections[element]
    }
    if ret!=self
      hook=section_created_hook(self,ret)
      ret = hook if hook.is_a? VyattaConfigSection
    end
    ret
  end

  # called when a new section is created
  def section_created_hook(sender,new_section)
    unless root?
      parent.section_created_hook(sender, new_section)
    else
      new_section
    end
  end

  def section_deleted_hook(sender,old_section)
    unless root?
      parent.section_deleted_hook(sender, old_section)
    end
  end

  public

  def delete(child_section)
    raise ArgumentError,"section #{child_section} is not my subsection" if
        child_section.parent!=self or not @subsections.key?(child_section.name) or @subsections[child_section.name]!=child_section
    ret = @subsections.delete(child_section.name)
    hook = section_deleted_hook(self,ret)
    ret=hook if hook.is_a? VyattaConfigSection
    ret
  end

  # @return [VyattaConfigSection]
  def parent
    @parent
  end

  def root
    s=self
    while not s.root?
      s=s.parent
    end
    s
  end

  def root?
    @parent.equal?(self)
  end

  def empty?
    @subsections.empty?
  end

  def name
    return "" if root?
    @name
  end

  def full_path
    return "" if root?
    parent_path=parent.full_path
    parent_path + (parent_path==""?"":" ") + quote(name)
  end

  def to_s
    return "" if root? and empty?
    pp.chomp
  end

  def to_hash
    return OrderedHash() if empty?
    @subsections.reduce(OrderedHash()) { |ret,(n,s)|
      ret[n]=s.to_hash
      ret
    }
  end

  # @param [VyattaConfigSection] other
  # @return array of [VyattaConfigSection] set difference self - other: sections that are descendants of self
  # but are not descendants of other
  def -(other)
    raise ArgumentError,"other must be a section" unless other.is_a? VyattaConfigSection
    return [self] if other.name!=name or (root? ^ other.root?)
    ret = []
    subsections.each { |n,v|
      if other.subsections.key?(n)
        ret += (v - other.subsections[n]) #recursive set difference
      else
        ret << v
      end
    }
    ret.flatten
  end

  # @param [VyattaConfigSection] other
  # @return [Boolean] if this section is a superset of the other
  def superset?(other)
    raise ArgumentError,"other must be a section" unless other.is_a? VyattaConfigSection
    (other-self).empty?
  end

  protected
  #pretty-print the current section
  #@param [Object] indent
  def pp(indent=0)
    ret = " "*indent + "#{quote(@name)}"
    case @subsections.count
    when 0
      ret += "\n"
    when 1
      ret += " "+@subsections.first[1].pp(indent).lstrip
    else
      ret += " {\n"
      @subsections.each { |n,s|
        ret += s.pp(indent+2)
      }
      ret += " "*indent + "}\n"
    end
    ret
  end

  def unquote(str)
    self.class.unquote str
  end

  def quote(str)
    self.class.quote(str)
  end

  public
  def self.unquote(str)
    str=~/^'([^']*)'$/ ? $1 : str
  end

  def self.quote(str)
    return str if !str || str.is_a?(Hash) || str.is_a?(Array)
    (str.include? " " or str.empty?) ? "'#{str}'" : str
  end

  def self.split_path(path)
    return path unless path.is_a?(String)
    path.scan(/(([^ \t']+)|('[^']*'))/).map { |m| unquote m[0] }
  end

  # @return [VyattaConfigSection]
  # @param block returns true if the section should be included in the result
  def select(settings={},&block)
    raise ArgumentError,"settings must be a hash" unless settings.is_a? Hash
    settings[:mode] ||= :depth_last
    known_modes = [:depth_last,:depth_first,:breadth_first,:children]
    raise ArgumentError,"settings[:mode] must be one of #{known_modes} but is #{settings[:mode]}" unless known_modes.include? settings[:mode]

    if block_given?
      work = lambda &block
      ret = []
      self.send("each_"+settings[:mode].to_s, &Proc.new() { |s|
          ret << s if work[s]
        })
      return ret
    end
    ret = []
    self.send("each_"+settings[:mode].to_s, &Proc.new() { |s|
      ret << s
    })
    return ret
  end

  def single(settings={},&block)
    select(settings,&block).first || settings[:default]
  end

  def [](name)
    raise KeyError,"unknown section #{name} in #{self}" unless @subsections.key? name
    @subsections.fetch(name)
  end

  def leaves
    select { |s|
      s.empty?
    }
  end

  def accumulate(state,&action)
    @subsections.each { |n,s|
      action[state,s]
    }
    state
  end

  def track_changes(&action)
    tracker_inst = ChangeTracker.new(self)

    self_class = class << self; self; end

    old_create_hook = self_class.instance_method(:section_created_hook)
    old_delete_hook = self_class.instance_method(:section_deleted_hook)

    self_class.instance_eval {
      define_method(:section_created_hook) do |sender,new_section|
        tracker_inst.track_create(sender,new_section)
        old_create_hook.bind(self).call(sender,new_section)
      end

      define_method(:section_deleted_hook) do |sender,old_section|
        tracker_inst.track_delete(sender,old_section)
        old_delete_hook.bind(self).call(sender,old_section)
      end
    }

    yield self

    self_class.instance_eval {
      define_method(:section_created_hook,old_create_hook)
      define_method(:section_deleted_hook,old_delete_hook)
    }

    tracker_inst
  end

  protected
  def each_depth_last(&action)
    @subsections.each { |n,s|
        s.each_depth_last(&action)
    }
    action[self]
  end

  def each_depth_first(&action)
    action[self]
    @subsections.each { |n,s|
      s.each_depth_first(&action)
    }
  end

  def each_breadth_first(&action)
    queue = [self]
    begin
      s=queue.shift
      action[s]
      queue += s.subsections.values
    end until queue.empty?
  end

  def each_children(&action)
    @subsections.each { |n,s|
      action[s]
    }
  end
end

class ChangeTracker < Array
  attr_reader :tracked_section

  def initialize(tracked_section)
    @tracked_section=tracked_section
  end

  def track_create(sender,section)
    self << change(:add,section)
  end

  def track_delete(sender,section)
    self << change(:delete,section)
  end

  private
  def change(type,section)
    ret = [type,section]
    class << ret
      def type
        self[0]
      end
      def section
        self[1]
      end
    end
    ret
  end
end
