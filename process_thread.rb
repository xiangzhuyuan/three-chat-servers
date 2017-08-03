a = []

def aaa(a)
  a.each do |o|
    puts o.to_s
  end
end
def bbb(a)
  puts 'this is bbb'
  a.each do |o|
    puts "#{o.to_s} ......"
  end
end

Thread.new do
  aaa a
end

fork do
  puts 'this is aform'
  bbb a
end

loop do
  1.upto 5 do |i|
    a.push i
  end
end
