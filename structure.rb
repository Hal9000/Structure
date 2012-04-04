#
# Structure
# Hal Fulton
# Version 1.0.3
# License: The Ruby License
#
# This is a newer version of the old "SuperStruct" (sstruct) library
#
# This is an easy way to create Struct-like classes; it converts easily
# between hashes and arrays, and it allows OpenStruct-like dynamic naming
# of members.
#
# Unlike Struct, it creates a "real" class, and it has real instance variables 
# with predictable names.
#
# A basic limitation is that the hash keys must be legal method names (unless
# used with send()).
#
# Basically, ss["alpha"], ss[:alpha], ss[0], and ss.alpha all mean the same.
#


class Structure

  def Structure.from_hash(hash)
    raise ArgumentError, "Expecting a hash" unless hash.is_a? Hash
    obj = Structure.new(hash)
  end

  def Structure.parse_hash(hash)
    # Like from_hash, only "deep"
    raise ArgumentError, "Expecting a hash" unless hash.is_a? Hash
    obj = Structure.new(hash)
    obj.members.each do |mem|
      setter = mem + "="
      this = obj.send(mem)
      if this.is_a? Hash 
        obj.send(setter, Structure.parse_hash(this, true)) unless this.empty?
      end
    end
    obj
  end

  def Structure.new(*args)
    @table = []
    @setsyms = []        # Setter symbols

    hash_flag = false
    klass = Class.new
    if (args.size == 1) 
      if args.first.is_a? Array
        args = args.first
      elsif args.first.is_a? Hash
        hash_flag = true
        hash = args.first
        args = hash.keys
        hash_vals = hash.values
      end
    end
    strs = args.map {|x| x.to_s }

    args.each_with_index do |k,i|
      case
        when (strs[i] !~ /[_a-zA-Z][_a-zA-Z0-9]*/)
          raise ArgumentError, "Illegal character"
        when k.is_a?(String)
          # ok
        when k.is_a?(Symbol)
          # ok
        when k.respond_to?(:to_str)
          k = k.to_str
	when (! [String,Symbol].include? k.class)
	  raise ArgumentError, "Need a String or Symbol, not '#{k}' (#{k.class})"
      end
      k = k.to_sym if k.is_a? String
      @table << k
      @setsyms << (k.to_s + "=").to_sym
      klass.instance_eval { attr_accessor k }
    end

    setsyms, table, vals =  @setsyms, @table, @vals

    klass.class_eval do
      attr_reader :singleton

      define_method(:initialize) do |*vals|
        n = vals.size
	m = table.size
	case 
	  when n < m
	    # raise ArgumentError, "Too few arguments (#{n} for #{m})"
	    # Never mind... extra variables will just be nil
	  when n > m
	    raise ArgumentError, "Too many arguments (#{n} for #{m})"
	end
        setsyms.each_with_index do |var,i|
          self.send(var,vals[i])
        end
      end

      define_method(:pretty_print) do |q|  # pp.rb support
        q.object_group(self) do
          q.seplist(self.members, proc { q.text "," }) do |member|
#         self.members.each do |member|
#           q.text ","  # unless q.first?
            q.breakable
            q.text member.to_s
            q.text '='
            q.group(1) do
              q.breakable ''
              q.pp self[member]
            end
          end
        end
      end

      define_method(:inspect) do
        str = "#<#{self.class||"anonymous"}:"
        table.each {|item| str << " #{item}=#{self.send(item)}" }
        str + ">"
      end

      define_method(:[]) do |*index|
        case index.map {|x| x.class }
	  when [Fixnum]
            self.send(table[*index])
          when [Fixnum,Fixnum], [Range]
	    table[*index].map {|x| self.send(x)}
	  when [String]
	    self.send(index[0].to_sym)
	  when [Symbol]
	    self.send(index[0])
        else
          raise ArgumentError,"Illegal index"
	end
      end

      define_method(:[]=) do |*index|
        value = index[-1]
        index = index[0..-2]
        case index.map {|x| x.class }
	  when [Fixnum]
            self.send(table[*index])
          when [Fixnum,Fixnum], [Range]
	    setsyms[*index].map {|x| self.send(x,value) }
	  when [String]
	    self.send(index[0].to_sym,value)
	  when [Symbol]
	    self.send(index[0],value)
        else
          raise ArgumentError,"Illegal index"
	end
      end

      define_method(:to_a)    { puts local_variables; table.map {|x| eval("@"+x.to_s) } }

      define_method(:to_ary)  { to_a }

      define_method(:members) { table.map {|x| x.to_s } }

      define_method(:to_struct) do
        mems = table
        Struct.new("TEMP",*mems)
        # Struct::TEMP.new(*vals) # Why doesn't this work??
        data = mems.map {|x| self.send(x) }
        Struct::TEMP.new(*data)
      end

      define_method(:to_hash) do
        hash = {}
	table.each do |mem|
          mem = mem.to_s
          hash.update(mem => self.send(mem))
        end
	hash
      end

      define_method(:assign) {|h| h.each_pair {|k,v| send(k.to_s+"=",v) } }

      # Class methods...

      @singleton = class << self
        self
      end

      @singleton.instance_eval do
        define_method(:members) do 
	  table.map {|x| x.to_s }
	end
        me = self
        define_method(:attr_tester) do |*syms| 
          syms.each {|sym| alias_method(sym.to_s+"?",sym) }
        end
      end

    end
    if hash_flag
      klass.new(*hash_vals)
    else
      klass
    end
  end


  def Structure.open(*args)
    klass = Structure.new(*args)

    setsyms, table, vals =  @setsyms, @table, @vals

    klass.class_eval do
      define_method(:method_missing) do |meth, *args|
        mname = meth.id2name
        if mname =~ /=$/
          getter = mname.chop
          setter = mname
        elsif mname =~ /\?$/
          raise NoMethodError  # ?-methods are not created automatically
        else
          getter = mname
          setter = mname + "="
        end
        gsym = getter.to_sym
        ssym = setter.to_sym
        ivar = "@" + getter
        setsyms << setter
        table << getter
        len = args.length
        if mname == getter
          klass.class_eval do                 # getter
            define_method(getter) do
              instance_variable_get(ivar)
            end
          end
        else
          klass.class_eval do                 # setter
            define_method(setter) do |*args|
              if len != 1
                raise ArgumentError, "Wrong # of arguments (#{len} for 1)", 
                      caller(1)
              end
              instance_variable_set(ivar,args.first)
              instance_variable_get(ivar)
            end
          end
        end
        if mname == setter
          self.send(setter,*args)
        else
          if len == 0
            self.send(getter)
          else
            raise NoMethodError, "Undefined method '#{mname}' for #{self}", 
                  caller(1)
          end
        end
      end
    end
    klass
  end

end


require "test-structure" if $0 == __FILE__
