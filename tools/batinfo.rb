#!/usr/bin/env ruby
ioreg = `/usr/sbin/ioreg -r -c AppleSmartBattery   -w 0 `
puts ioreg
#max = ioreg.match(/"MaxCapacity" = ([\d]+)/)[1].to_f rescue nil
#current = ioreg.match(/"CurrentCapacity" = ([\d]+)/)[1].to_f rescue nil
#puts "#{(current.to_f / max.to_f)}"
