#
# Structure test code
# Hal Fulton
# Version 1.0.3 (in sync with library code)
# License: The Ruby License
#

require "test/unit"
require "structure"
require 'pp'


class Tester < Test::Unit::TestCase

  def test001
    # Must pass in String or Symbol
    assert_raises(ArgumentError) { Structure.new(0) }
  end
  
  def test001a
    # Honors the to_str method
    Regexp.class_eval { define_method(:to_str) { self.to_s.split(":").last[0..-2] } }
    klass = nil
    assert_nothing_raised(ArgumentError) { klass = Structure.new(/abc/) }
    assert_equal(["abc"],klass.members)
    Regexp.class_eval { undef_method(:to_str) }
  end
  
  def test002
    # Must pass in valid name(s)
    assert_raises(ArgumentError) { Structure.new("###") }
  end
  
  def test003
    # Can't assign to nonexistent fields
    myStruct = Structure.new
    assert_raises(ArgumentError) { myStruct.new(345) }
  end
  
  def test004
    # Need not assign to existing fields (default to nil)
    myStruct = Structure.new(:alpha)
    assert_nothing_raised(ArgumentError) { myStruct.new }
  end
  
  def test005
    # A value assigned at construction may be retrieved
    myStruct = Structure.new(:alpha)
    x = myStruct.new(234)
    assert(x.alpha == 234)
  end
  
  def test006
    # Unassigned fields are nil
    myStruct = Structure.new(:alpha,:beta)
    x = myStruct.new(234)
    assert(x.beta == nil)
  end
  
  def test007
    # An open structure still may not construct with nonexistent fields
    myStruct = Structure.open
    assert_raises(ArgumentError) { x = myStruct.new(234) }
  end
  
  def test008
    # An open structure may assign fields not previously existing
    myStruct = Structure.open
    x = myStruct.new
    assert_nothing_raised { x.foobar = 123 }
  end
  
  def test009
    # A field assigned to an open struct after its construction may be retrieved
    myStruct = Structure.open
    x = myStruct.new
    x.foobar = 123
    assert(x.foobar == 123)
  end
  
  def test010
    # The act of retrieving a nonexistent field from an open struct will
    # create that field
    myStruct = Structure.open
    x = myStruct.new
    assert_nothing_raised { y = x.foobar }
  end
  
  def test011
    # A field (in an open struct) that is unassigned will be nil
    myStruct = Structure.open
    x = myStruct.new
    y = x.foobar
    assert(y == nil)
  end
  
  def test012
    # A struct created with new rather than open cannot reference nonexistent
    # fields
    myStruct = Structure.new
    x = myStruct.new
    assert_raises(NoMethodError) { y = x.foobar }
  end
  
  def test013
    # Adding a field to a struct will create a writer and reader for that field
    myStruct = Structure.new(:alpha)
    x = myStruct.new
    x.send(:alpha=,1)
    assert(x.alpha == 1)
  end
  
  def test014
    # Only a single value may be passed to a writer (for code coverage)
    myStruct = Structure.new(:alpha)
    x = myStruct.new
    assert_raises(ArgumentError) { x.send(:alpha=,1,2) }
  end
  
  def test015
    # An open struct will also create a writer and a reader together
    myStruct = Structure.open
    x = myStruct.new
    x.send(:alpha=,1)
    assert(x.alpha == 1)
  end
  
  def test016
    # Only a single value may be passed to a writer (for code coverage)
    myStruct = Structure.open
    x = myStruct.new
    assert_raises(ArgumentError) { x.send(:alpha=,1,2) }
  end
  
  def test017
    # A field has a real writer and reader corresponding to it
    myStruct = Structure.new(:alpha)
    x = myStruct.new
    assert(myStruct.instance_methods.include?("alpha"))
    assert(myStruct.instance_methods.include?("alpha="))
  end
  
  def test018
    # Creating a field by retrieval in an open struct will NOT create a writer 
    # (This behavior has changed!)
    myStruct = Structure.open
    x = myStruct.new
    y = x.alpha
    assert(myStruct.instance_methods.include?("alpha"))
    assert(!myStruct.instance_methods.include?("alpha="))
  end
  
  def test019
    # Creating a field by writing in an open struct will NOT create a reader
    # (This behavior has changed!)
    myStruct = Structure.open
    x = myStruct.new
    x.alpha = 5
    assert(myStruct.instance_methods.include?("alpha="))
    assert(!myStruct.instance_methods.include?("alpha"))
  end
  
  def test020
    # A string will work as well as a symbol
    myStruct = Structure.new("alpha")
    x = myStruct.new
    assert(myStruct.instance_methods.include?("alpha"))
    assert(myStruct.instance_methods.include?("alpha="))
  end
  
  def test021
    # to_a will return an array of values
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    assert(x.to_a == [7,8,9])
  end
  
  def test022
    # Instance method 'members' will return a list of members (as strings)
    myStruct = Structure.new(:alpha,"beta")
    x = myStruct.new
    assert_equal(["alpha","beta"],x.members)
  end
  
  def test023
    # Class method 'members' will return a list of members (as strings)
    myStruct = Structure.new(:alpha,"beta")
    assert_equal(["alpha","beta"],myStruct.members)
  end
  
  def test024
    # to_ary will allow a struct to be treated like an array in
    # multiple assignment
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    a,b,c = x
    assert(b == 8)
  end
  
     def aux025(*arr)  # Just used in test 25
       arr[1]
     end
  
  def test025
    # to_ary will allow a struct to be treated like an array in
    # passed parameters
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    b = aux025(*x)
    assert(b == 8)
  end
  
  def test026
    # to_hash will return a hash with fields as keys
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    h = x.to_hash
    assert_equal({"alpha"=>7,"beta"=>8,"gamma"=>9},h)
  end
  
  def test027
    # A field name (String) may be used in a hash-like notation
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    y = x["beta"]
    assert(8,y)
  end
  
  def test028
    # A field name (Symbol) may be used in a hash-like notation
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    y = x[:beta]
    assert(8,y)
  end
  
  def test029
    # [offset,length] may be used as for arrays
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    y = x[0,2]
    assert([7,8],y)
  end
  
  def test030
    # Ranges may be used as for arrays
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    y = x[1..2]
    assert([8,9],y)
  end
  
  def test031
    # Adding a field to an open struct adds it to the instance
    myStruct = Structure.open(:alpha)
    x = myStruct.new
    x.beta = 5
    assert_equal(["alpha","beta"],x.members)
  end
  
  def test032
    # Adding a field to an open struct adds it to the class also
    myStruct = Structure.open(:alpha)
    x = myStruct.new
    x.beta = 5
    assert_equal(["alpha","beta"],myStruct.members)
  end
  
  def test033
    # An array passed to Structure.new need not be starred
    myStruct = Structure.new(%w[alpha beta gamma])
    x = myStruct.new
    assert_equal(%w[alpha beta gamma],x.members)
  end
  
  def test034
    # A hash passed to Structure.new will initialize the values
    # and return a structure, not a class
    hash = {"alpha"=>234,"beta"=>345,"gamma"=>456}
    obj = Structure.new(hash)
pp obj
    assert_equal(%w[alpha beta gamma],obj.members.sort) # sort for Ruby 1.8
    assert_equal(345, obj.beta)
#   assert false, "Not implemented yet."
  end
  
  def test035
    # A hash passed to #assign will set multiple values at once
    myStruct = Structure.new(%w[alpha beta gamma])
    x = myStruct.new
    hash = {"alpha"=>234,"beta"=>345,"gamma"=>456}
    x.assign(hash)
    assert_equal([234,345,456], x.to_a)
  end
  
  def test036
    # Make sure ||= works properly
    x = Structure.open.new
    x.foo ||= 333
    x.bar = x.bar || 444
    assert_equal(333,x.foo)
    assert_equal(444,x.bar)
  end

  def test037
    # A simple array index works ok
    myStruct = Structure.new("alpha","beta","gamma")
    x = myStruct.new(7,8,9)
    assert_equal(7,x[0])
    assert_equal(8,x[1])
    assert_equal(9,x[2])
  end

  def test038
    # attr_tester will create a ?-method
    klass = Structure.new(:alpha,:beta,:gamma)
    klass.attr_tester :alpha, :gamma
    x = klass.new(22,33,nil)
    assert(x.alpha?)
    assert_raises(NoMethodError) { x.beta? }
    assert(! x.gamma?)
  end

  def test039
    # attr_tester works with open() (?-methods not created)
    klass = Structure.open(:alpha,:beta,:gamma)
    klass.attr_tester :alpha, :gamma
    x = klass.new(22,33,nil)
    assert(x.alpha?)
    assert_raises(NoMethodError) { x.beta? }  # ?-methods are not automatic
    assert(! x.gamma?)
  end

  def test040
    # two classes don't interfere with each other
    klass1 = Structure.new(:alpha, :beta, :gamma)
    klass2 = Structure.new(:delta, :epsilon)
    x1 = klass1.new(1,2,3)
    x2 = klass2.new(4,5)
    pp x1
    pp x2
  end
  
end
