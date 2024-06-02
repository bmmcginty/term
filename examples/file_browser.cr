require "../src/term"

class FileListControl < ListControl
  @path : String
  @positions = Hash(String, Int32).new
  @entries = Hash(String, Array(String)).new

  def key(k)
    refresh = false
    refresh = if k == 8.chr || k == 127.chr
                back
              elsif k == 13.chr
                enter
              else
                return super
              end
    if refresh
      @dirty = true
      self.parent.as(MainWindow).refresh
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

  def back
    p = File.dirname(@path)
    Log.info { "changing from #{@path} to #{p}" }
    if !@entries[p]?
      Log.info { "adding #{p}" }
      add p
    end
    @path = p
    true
  end

  def enter
    v = pos
    child = @entries[@path][v]
    p = @path + "/" + child
    if !File.directory?(File.realpath(p))
      return
    end
    if !@entries[p]?
      add p
    end
    @path = p
    true
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
lb = FileListControl.new height: 20
a.add lb
a.run
a.refresh
sleep
