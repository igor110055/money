count = 0
sum = 0
from = 9000
to = 1000
months = 12*6
sp = ((to-from)/months).to_i
invest_array = (from..to).step(sp).to_a
invest_array.each do |n|
  sum += n
  puts "#{count}:#{n}:#{sum}"
  count += 1
end
# puts "Invest Max:#{(300000/4.6).to_i} CNY"
puts "Invest Max:#{2300*36*2} CNY"
puts "$trial_month_invest = (#{from}..#{to}).step(#{sp}).to_a"
