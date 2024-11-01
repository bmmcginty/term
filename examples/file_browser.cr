require "../src/term"

Log.enable_info

class FileListControl < ListControl
@@clipboard = Array(String).new
@@action=""
@name_control : StaticTextControl? = nil
@status_control : StaticTextControl? = nil
  @path : String
  @positions = Hash(String, Int32).new
  @entries = Hash(String, Array(String)).new

def path=(s)
@path=s
set_name?
end

action def cut
@@action="cut"
@@clipboard.clear
@@clipboard << "#{@path}/#{items[self.pos]}"
end

action def copy
@@action="copy"
@@clipboard.clear
@@clipboard << "#{@path}/#{items[self.pos]}"
end

action def paste
@@clipboard.each do |i|
handle_clipboard i
end # each
@@action=""
@@clipboard.clear
end # def

def handle_clipboard(i)
opath=i
npath="#{@path}/#{File.basename(opath)}"
if @@action=="cut"
`mv "#{opath}" "#{npath}"`
elsif @@action=="copy"
`cp -R "#{opath}" "#{npath}"`
else
end
srcdir=File.dirname(i)
fms=main_window.all_children.select {|i| i.is_a?(FileListControl) }
fms.each do |i|
i=i.as(FileListControl)
i.hydrate srcdir
i.hydrate @path
end # each fms
end

def focus
set_name?
super
end

def set_name?
if @name_control
@name_control.not_nil!.text=File.basename(@path)
end
end

  def pos=(v : Int32)
    @positions[@path] = v
  end

  def pos : Int32
    @positions[@path]
  end

  def items : Iterable
    @entries[@path]
  end

  action def backspace
    p = File.dirname(@path)
    Log.info { "changing from #{@path} to #{p}" }
    if p == @path
      @dirty = false
      return
    end
    if !@entries[p]?
      Log.info { "adding #{p}" }
      hydrate p
    end
    self.path = p
  end

  action def select_item
    v = pos
    child = @entries[@path][v]
    p = @path + "/" + child
    if !File.directory?(File.realpath(p))
      @dirty = false
      return
    end
    if !@entries[p]?
      hydrate p
    end
    self.path = p
  end

  def hydrate(p)
    l = Dir.children(p)
    l.sort!
    @entries[p] = l
size=@entries[p].size
cur=@positions[p]?
if ! cur
cur=0
end
if cur>=size
size-1
end
if cur<0
cur=0
end
@positions[p]=cur
  end

  def initialize(@height = nil, @name_control = nil, @status_control=nil)
    hydrate Dir.current
    @path = Dir.current
  end
end

a = MainWindow.new
tb=StaticTextControl.new text: "", height: 1, focusable: false
a.add tb, y: 0
st=StaticTextControl.new text: "", height: 1, focusable: false
a.add st, y: 21
frame1 = FrameControl.new
a.add frame1, y: 1
frame2 = FrameControl.new
a.add frame2, y: 1
lb1 = FileListControl.new height: 20, name_control: tb, status_control: st
frame1.add lb1
lb2 = FileListControl.new height: 20, name_control: tb, status_control: st
frame2.add lb2
# wz=KeyWizard.new height: 20
# frame.add wz, y: 0
a.run
a.refresh
sleep
