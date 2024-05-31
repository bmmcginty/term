require "./static_text"

class EditControl < StaticTextControl
@pos=0

def next_char
@dirty=true
@pos+=1
if @pos>@text.size
@pos=@text.size
end
end

def prev_char
@dirty=true
@pos-=1
if @pos<0
@pos=0
end
end

def insert(t)
@dirty=true
tmp=@text.split("")
tmp.insert @pos, t.to_s
@pos+=1
@text=tmp.join("")
end

def backspace
if @pos==0
return
end
@dirty=true
t=@text.split("")
t.delete_at @pos-1
@text=t.join("")
@pos-=1
end

def user_x
#chunk=@pos/width
@pos%width
end

def text
w=width
# chunks will be zero based (0 for 0-39, 1 for 40-79, ...)
if @text.size<=w
return @text
end
start=0
stop=w
while ! (start<=@pos<stop)
start+=w
stop+=w
end
@text[start...stop]
end

def key(k)
case k
when :right
next_char
when :left
prev_char
when Char
o=k.ord
if o==8 || o==127
backspace
elsif 32<=o<=126
insert k
else
return :continue
end # if
else
return :continue
end # case
parent.as(MainWindow).refresh
end # def

end # class
