


module MUD
  class Player < MUD::Movable
  
    # construct a new Player
    def initialize
      super
      @desc = ""
      @parent = nil
      @role = nil
      @login_name = nil
      @password = nil
	    @status = nil
	    @lastwhisper = nil
	    @items = Array.new
	    @keys = Array.new
	    @keycopies = Array.new
	    @attrib = Hash.new
    end
    
    # normal to_s method
    def to_s
	    arr = Array.new
	    arr.push(['empty'])
	    arr.push(['fixed'])
	    arr.push(['headline', @name])
	    @attrib.keys.sort.each do |k|
	      arr.push(['leftnofill', k.gsub(/\_/, " ") + ":", @attrib[k]])
	    end
	    arr.push(['fixed'])
	    arr.push(['nofill', "Items"])
	    plarr = Array.new
	    @items.each do |p|
	      plarr.push 'nofill' if plarr.empty?
	      plarr.push p.name
		    if plarr.length == 5
		      arr.push plarr
		      plarr.clear
		    end
	    end
	    arr.push plarr if plarr.length > 1
	    arr.push(['fixed'])
	    return SUPPORT::Format::format(arr)
    end
    
    # lists the properties of the player
	  # [returns:]			array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "name: #{self.name}"
	    output.push "login-name: #{self.login_name}"
      output.push "role: #{self.role}"
	    output.push "items: "
	    for i in 0...@items.length
	      it = @items[i]
		    output[output.length - 1] += "#{it.id}"
		    output[output.length - 1] += ", " if i < @items.length - 1
	    end
	    output.push "keys: "
	    for i in 0...@keys.length
	      k = @keys[i]
	      output[output.length - 1] += "#{k.id}"
	      output[output.length - 1] += ", " if i < @keys.length - 1
	    end
	    output.push "keycopies: "
	    for i in 0...@keycopies.length
	      kc = @keycopies[i]
	      output[output.length - 1] += "#{kc.id}"
	      output[output.length - 1] += ", " if i < @keycopies.length - 1
	    end
      output.push "attribs: "
	    for i in 0...@attrib.keys.length
	      k = @attrib.keys[i]
        v = @attrib[k]
	      output[output.length - 1] += "#{k}=#{v}"
	      output[output.length - 1] += ", " if i < @attrib.keys.length - 1
	    end
      
	    return output
	  end
    
    # to_desc method
    def to_desc
	    arr = Array.new
	    arr.push(['leftnofill', @desc])
	    return SUPPORT::Format::format(arr)
    end
    
    attr_accessor :desc, :role, :login_name, :password, :parent, :status, :lastwhisper, :items, :keys, :keycopies, :attrib
  end
end
