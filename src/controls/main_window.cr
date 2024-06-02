require "../linux_terminal"
require "./control"

class MainWindow < Control
@active_control : Control? = nil
@term = LinuxTerminal.new
@refresh_channel = Channel(Int32).new

getter! active_control

# todo: remove this and change to 
# use #key and #string
def unprocessable
@term.unprocessable
end

def active_control=(control : Control)
@active_control=control
control.focus
end

def initialize
read_keys
@term.run
t=@term.size
@height=t[:y]
@width=t[:x]
Process.on_terminate do |reason|
terminate
end
at_exit do |reason, exc|
Log.info {"at_exit called reason #{reason} exc #{exc}"}
terminate
end
end

def terminate
@term.done
Process.exit
end

def focusable?
false
end

def text
""
end

def focus
end

def key(k)
case k
when '\t'
ac=all_children.to_a
idx=ac.index(active_control).not_nil!
idx+=1
if idx==ac.size
idx=1
end
self.active_control=ac[idx]
refresh
when 17.chr
Log.info {"exitting"}
exit
#Process.kill Process.pid
end # select
end # def

def run
if children.size==0
raise Exception.new("main window must have children")
end
self.active_control=children[0]
react_to_keys
handle_refresh
end

def handle_refresh
spawn do
while @refresh_channel.receive
do_refresh
end # while
end # spawn
sleep 0
end # def

def handle_key(k)
Log.info {"handle_key #{k}"}
t=active_control
while t
v=t.key k
if v!=:continue
break
end
t=t.parent?
end
end # def

def react_to_keys
spawn do
while 1
t=@term.getkey
handle_key t
end # while
end # spawn
sleep 0
end # def

def read_keys
tmp=Channel(Int32).new(1)
spawn do
tmp.send 0
while 1
t=STDIN.read_byte.not_nil!
@term.input_channel.send t
end #while
end #spawn
sleep 0
tmp.receive
end # def

def all_children
ret=[] of Control
tmp=[] of Control
tmp << self
while tmp.size>0
t=tmp.delete_at(0)
ret << t
t.children.reverse_each do |c|
tmp.insert 0, c
end # each child
end # while tmp
ret
end

def refresh
@refresh_channel.send 0
end

def do_refresh
all_children.each do |c|
if ! c.dirty
next
 end # if
c.text.split("\n").each_with_index do |line, idx|
@term.move c.y+idx,c.x
@term.write line.ljust(c.width, ' ')
end # each line
c.dirty=false
end # each child
@term.move y: active_control.y+active_control.user_y, x: active_control.x+active_control.user_x
end # def

end # class
