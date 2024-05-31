require "./terminal"
require "./fix"

class LinuxTerminal < Terminal
@tty : IO::FileDescriptor
getter! input_channel, tty

def getkey()
Log.info {"getkey"}
t=input_channel.receive
Log.info {"ipr #{t}"}
if t!=27
return read_utf8 t
end
spc=read_special t
Log.info {"spec #{spc}"}
if spc.is_a?(Symbol)
return spc
end
tag=key_to_uint64(spc.as(String))
if @keys[tag]?
@keys[tag]
else
@unprocessable << spc.as(String)
:special
end
end

def read_utf8(byte)
#log "read_utf8"
code=0
seen=0
length = if (byte >> 7) == 0
1
elsif (byte >> 5) == 0b110
2
elsif (byte >> 4) == 0b1110
3
elsif (byte >> 3) == 0b11110
4
else
raise Exception.new("invalid length for unicode")
end
while seen<length
if seen>0
byte=input_channel.receive
end
code = code << 8
code += byte
seen+=1
end
code.chr
end

def read_special(first_byte)
byte=nil
select
when t=input_channel.receive
byte=t
when timeout((0.1).seconds)
end
if byte==nil
return :escape
end
byte=byte.not_nil!
if byte=='['.ord
read_special_csi byte
elsif byte==']'.ord || byte=='X'.ord
read_special_terminated byte
elsif byte==27
:escape
elsif byte=='O'.ord
select
when t=input_channel.receive
@unprocessable << "O#{t.chr}"
when timeout((0.1).seconds)
@unprocessable << "O"
end
:special
else
@unprocessable << "#{first_byte.chr}#{byte.chr}"
:special
end
end

def read_special_csi(type)
#log "read_special_csi"
# type will == '['.ord
pos=-1
out=""
out+=type.chr
while t=input_channel.receive
pos+=1
out+=t.chr
Log.info {"out #{out.inspect}"}
if 0x40 <= t <= 0x7e
break
end #if
end #while
out
end #def

def read_special_terminated(byte)
#log "read_special_terminated"
out=""
out+=byte.chr
while t=input_channel.receive
out+=byte.chr
#terminate on \e\ (esc backslash)
if out.ends_with?(esc+"\\")
out=out[0..-2]
break
end
end
out
end

# turns a multi-byte key sequence into an uint64
def key_to_uint64(s)
t=0_u64
s.each_char do |char|
t=t<<8
t+=char.ord
end
t
end

# assign keys from an array to the @keys hash
def set_keymap(l)
idx=0
while idx+1<l.size
@keys[key_to_uint64(l[idx].as(String))]=l[idx+1].as(Symbol)
idx+=2
end
end

def set_default_keys
set_keymap [
"[\u00FF", :unknown,
"[D", :left,
"[H", :home,
"[B", :down,
"[C", :right,
"[A", :up,
"[M", :f1,
"[N", :f2,
"[O", :f3,
"[P", :f4,
"[Q", :f5,
"[R", :f6,
"[S", :f7,
"[T", :f8,
"[U", :f9,
"[V", :f10,
"[W", :f11,
"[X", :f12
]
end

def initialize
@tty=STDOUT
tty.raw!
tty.noecho!
set_default_keys
end

def run
Log.info {"get size"}
# get size
size
clear
top
end

def done
clear
tty.cooked!
tty.echo!
end

def top
move 0,0
end

def bottom
move @maxy,0
end

def title(s)
send esc, osc, "0;#{s}", esc, oscts
end

def move(y,x)
send esc, csi, "#{y+1};#{x+1}H"
end

def clear
send esc, csi, "2J"
end

private def getpos
send esc, csi, "6n"
t=getkey
Log.info {"getkey got #{t}"}
if t != :special
raise Exception.new("no response received for curpos")
end
s=@unprocessable.delete_at 0
s=s[1..-2]
Log.info {"s #{s}"}
s.split(";").map &.to_i
end

def size
if @init
return {x: @maxx, y: @maxy}
end
Log.info {"getpos"}
move 1000,1000
y,x=getpos
move 0,0
@init=true
@maxy=y-1
@maxx=x-1
return {x: @maxx, y: @maxy}
end

def write(text)
tty << text
end

def up
send esc, "EM"
end

def down
send '\n'
end

def esc
'\u001b'
end

def csi
'['
end

def osc
']'
end

def oscts
'\\'
end

def send(*things)
tty << things.map(&.to_s).join("")
end

end
