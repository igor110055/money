module MyString
  refine String do
    def to_i
      return 100
    end
  end
end

using MyString
puts "ABCD".to_i
