require "../src/term"

Log.enable_info

class FMInput < EditControl
  @fl : FileListControl? = nil
  @call : Proc(String, Nil)? = nil

  def activate(fl : FileListControl, &block : (String -> Nil))
    @call = block
    @fl = fl
    main_window.active_control = self
  end

  action def insert_line
    @call.not_nil!.call self.text
    main_window.active_control = @fl.not_nil!
  end
end

class FileListControl < ListControl
  @@clipboard = Array(String).new
  @@action = ""
  @name_control : StaticTextControl? = nil
  @status_control : StaticTextControl? = nil
  @edit_control : FMInput? = nil
  @path : String
  @positions = Hash(String, Int32).new
  @entries = Hash(String, Array(String)).new
  @filter = ""

  def path=(s)
    @path = s
    set_name?
  end

  action def activate_filter
    if !@edit_control
      @dirty = false
      return
    end
    @@action = "filter"
    @edit_control.not_nil!.activate self do |i|
      @filter = i
    end
  end

  action def tag_item
    t = "#{@path}/#{real_items[self.pos]}"
    if @@clipboard.includes?(t)
      @@clipboard.delete t
    else
      @@clipboard << t
    end
  end

  action def undo
    @@action = ""
    self.set_status ""
  end

  action def cut
    self.set_status ""
    if @@action != ""
      self.set_status "undo your #{@@action} to cut again"
      @dirty = false
      return
    end
    @@action = "cut"
    if @@clipboard.size < 2
      @@clipboard.clear
      @@clipboard << "#{@path}/#{items[self.pos]}"
    end
  end

  action def copy
    self.set_status ""
    if @@action != ""
      self.set_status "undo your #{@@action} to copy again"
      @dirty = false
      return
    end
    @@action = "copy"
    if @@clipboard.size < 2
      @@clipboard.clear
      @@clipboard << "#{@path}/#{items[self.pos]}"
    end
  end

  action def paste
    self.set_status ""
    @@clipboard.each do |i|
      handle_clipboard i
    end # each
    @@action = ""
    @@clipboard.clear
  end # def

  def handle_clipboard(i)
    opath = i
    npath = "#{@path}/#{File.basename(opath)}"
    if @@action == "cut"
      `mv "#{opath}" "#{npath}"`
    elsif @@action == "copy"
      `cp -R "#{opath}" "#{npath}"`
    else
    end
    srcdir = File.dirname(i)
    fms = main_window.all_children.select { |i| i.is_a?(FileListControl) }
    fms.each do |i|
      i = i.as(FileListControl)
      i.hydrate srcdir
      i.hydrate @path
    end # each fms
  end

  def focus
    set_name?
    if self.pos >= @entries[@path].size
      self.pos = @entries[@path].size - 1
    end
    super
  end

  def set_status(t)
    if @status_control
      @status_control.not_nil!.text = t
    end
  end

  def set_name?
    if @name_control
      @name_control.not_nil!.text = File.basename(@path)
    end
  end

  def pos=(v : Int32)
    @positions[@path] = v
  end

  def pos : Int32
    @positions[@path]
  end

  def real_items : Iterable
    ret = @entries[@path]
    if @filter.size > 0
      ret.select { |i| File.match?(@filter, i) }
    else
      ret
    end
  end

  def items : Iterable
    t = real_items.dup
    if @@clipboard.size > 0
      t.map! { |i| i + (@@clipboard.includes?(@path + "/" + i) ? "*" : "") }
    end
    t
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
    l.sort_by! do |i|
      ({
        (File.info(p + "/" + i, follow_symlinks: false).type.directory? ? 0 : 1),
        i,
      })
    end
    @entries[p] = l
    size = @entries[p].size
    cur = @positions[p]?
    if !cur
      cur = 0
    end
    if cur >= size
      size - 1
    end
    if cur < 0
      cur = 0
    end
    @positions[p] = cur
  end

  def initialize(@height = nil, @name_control = nil, @status_control = nil, @edit_control = nil)
    hydrate Dir.current
    @path = Dir.current
  end
end

a = MainWindow.new
tb = StaticTextControl.new text: "", height: 1, focusable: false
a.add tb, y: 0
st = StaticTextControl.new text: "", height: 1, focusable: false
a.add st, y: 21
et = FMInput.new text: "", height: 1, focusable: false
a.add et, y: 22
frame1 = FrameControl.new
a.add frame1, y: 1
frame2 = FrameControl.new
a.add frame2, y: 1
lb1 = FileListControl.new height: 20, name_control: tb, status_control: st, edit_control: et
frame1.add lb1
lb2 = FileListControl.new height: 20, name_control: tb, status_control: st, edit_control: et
frame2.add lb2
# wz=KeyWizard.new height: 20
# frame.add wz, y: 0
a.run
a.refresh
sleep
