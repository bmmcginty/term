require "./control"

class StaticTextControl < Control
@text : String

getter text

def text=(@text)
@dirty=true
end # def

def initialize(@text, @height=nil, @width=nil)
end

def focusable?
true
end

def key(k)
:continue
end

end # class

