class ListControl(T) < Control
@items : Array(T)

@pos=0

def focusable?
true
end

def key(k)
:continue
end

def text
""
end

def user_y
pos%@items.size
end

def initialize(@items, @height=nil, @width=nil)
end

end # class

