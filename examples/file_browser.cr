require "../src/term"

class FileListControl < ListControl
  @path : String
  @positions = Hash(String, Int32).new
  @entries = Hash(String, Array(String)).new

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
      add p
    end
    @path = p
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
      add p
    end
    @path = p
  end

  def add(p)
    l = Dir.children(p)
    l.sort!
    @entries[p] = l
    @positions[p] = 0
  end

  def initialize(@height = nil)
    add Dir.current
    @path = Dir.current
  end
end

a = MainWindow.new
frame = Frame.new
a.add frame
lb = FileListControl.new height: 20
frame.add lb
# wz=KeyWizard.new height: 20
# frame.add wz, y: 0
a.run
a.refresh
sleep
