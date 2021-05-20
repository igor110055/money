class MyClass
  def mp(x,y)
    x * y * 2
  end
end

obj = MyClass.new
puts obj.mp(3,2)
puts obj.send(:mp,4,3)
