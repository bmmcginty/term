require "./control"

class StaticTextControl < Control
  @text : String
@focusable : Bool

  getter text
setter focusable

  def text=(t)
Log.info { "~ set text to #{t}" }
@text=t
    @dirty = true
  end # def

def wrap(text, len)
ret=[] of String
t=text
while t.size>len
pos=t.rindex(/[\n ]/,len)
if pos
ret << t[0...pos]
t=t[pos+1..-1]
else
ret << t[0...len]
t=t[len..-1]
end # if
end # while
ret << t
ret
end # def

action def next_line
if @user_y>=self.height-1
@dirty=false
return
end
@user_y+=1
end

action def previous_line
if @user_y==0
@dirty=false
return
end
@user_y-=1
end

def paint(term)
w=wrap(text,self.width)[0...self.height].join("\n\r")
Log.info { "painting #{self} y #{self.y} x #{self.x} width #{self.width} height #{self.height}" }
Log.info { "w #{w.inspect} text #{text.inspect}" }
  term.move self.y, self.x
term.write ([" "*self.width]*self.height).join("\n\r")
term.move self.y, self.x
term.write w
term.move @user_y, @user_x
end

  def initialize(@text, @height = nil, @width = nil, @focusable=true)
  end

  def focusable?
    @focusable
  end

end # class
