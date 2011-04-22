

module SUPPORT
  class Math
    
    # Calculate the Signum of a decimal/number
    # [param num:]      input for Signum
    # [returns:]        if num > 0: 1, if num < 0: -1 and else 0
    def Math::sgn (num)
      if num > 0
        return 1
      elsif num < 0
        return -1
      else
        return 0
      end
    end
    
    # Randomized Signum
    # [returns:]        equally distributed either 1 or -1
    def Math::rand_sgn
      if rand(3) <= 1
        return -1
      else
        return 1
      end
    end
    
    # Round function
    # [param num:]      decimal to be rounded
    # [param decimals:] number of decimals behind comma
    # [returns:]        rounded decimal
    def Math::round (num, decimals)
      t = num * (10 ** decimals)
      t.round.to_f
      return t / (10 ** decimals)
    end
    
    # Making sure the number is a percent value
    # [param num:]      number assumed to be percent
    # [returns:]        number in the range of [0,99]
    def Math::percent (num)
      if num > 99
        return 99
      elsif num < 0
        return 0
      else
        return num
      end
    end
  end
  
  class Format
	# Format the given array into a proper output message
	# [param input:]		2 dimensional array for each line and amount of words for output
	# [returns:]			  properly formated string
	def Format::format (input)
		str = ""
		for i in 0...input.length
			line = input[i]
			instruction = line[0]
			if instruction == 'fixed'
				for k in 0...$TEXT_WIDTH
					str += "-"
				end
			elsif not line.length - 1 == 0
				items = line.length - 1
				size_item = ($TEXT_WIDTH / items).floor
				for j in 1...line.length
					item = line[j]
					if instruction == 'fill' or instruction == 'nofill' or instruction == 'leftnofill'
						fillarray = Array.new
						while item.size > size_item
							fillarray.push item[0,size_item]
							item = item[size_item,item.size - size_item]
						end
						fillarray.push item
						fillarray = fillarray.reverse
						while not fillarray.empty?
							item = fillarray.pop
							fillsize = ((size_item - item.size) / 2).floor
							k = 0
							while k < size_item and not instruction == 'leftnofill'
								if k < fillsize or k >= fillsize + item.size
									str += "-" if instruction == 'fill'
									str += " " if instruction == 'nofill'
								elsif k < fillsize + item.size
									str += item[k-fillsize].chr
								end
								k += 1
							end
							while k < size_item and instruction == 'leftnofill'
								if k < item.size
								  str += item[k].chr
								elsif k < size_item
									str += " "
								end
								k += 1
							end
							#str += item if instruction == 'leftnofill'
							str += "%n" if not fillarray.empty? and fillarray.length + j - 1 % items == 0
						end
					elsif instruction == 'headline'
						size_item = item.size
						mid = (($TEXT_WIDTH - size_item - 2) / 2).floor
						temp = ""
						for k in 0...mid
							temp += "-"
						end
						str += temp + "[#{item}]" + temp
						break
					end
				end
			end
			str += "%n"
		end
		return str
	end
  end
end
