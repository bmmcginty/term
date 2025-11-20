require "../linux_terminal"
require "./control"
require "yaml"

class MainWindow < Control
  @active_control : Control? = nil
  @term = LinuxTerminal.new
  @refresh_channel = Channel(Int32).new
  @keys = Hash(String, Array(String)).new

  getter! active_control
  getter keys

  def active_control=(control : Control)
    @active_control = control
    control.focus
  end

  def initialize
    @main_window = self
    load_keys
    read_keys
    # bind keys for main window (because we don't "add" our self)
    bind_keys
    @term.run
    t = @term.size
    @height = t[:y]
    @width = t[:x]
    Process.on_terminate do |reason|
      terminate
    end
    at_exit do |reason, exc|
      Log.info { "at_exit called reason #{reason} exc #{exc}" }
      terminate
    end
  end

  def terminate
    @term.done
    Process.exit
  end

  def load_keys
    path = Path["~/.term-cr.yml"].expand(home: true)
    if !File.exists?(path)
      File.write(path, "all:\n  exit: ctrl-q")
    end
    y = YAML.parse(File.read(path))
    proc = File.basename(Process.executable_path.not_nil!)
    add_keys y["all"]
    if y[proc]?
      add_keys y[proc]
    end
    sort_keys
  end # def

  def sort_keys
    @keys.each do |k, v|
      v.reverse!
    end
  end # def

  def add_keys(keys)
    keys.as_h.each do |k, vl|
      k = k.as_s.gsub("-", "_")
(vl.as_s? ? [vl] : vl.as_a).each do |v|
      v = v.as_s
      if v == "nil"
        @keys.delete k
      end
      if !@keys[v]?
        @keys[v] = [] of String
      end
      @keys[v] << k
end # each
    end # each
  end   # def

  # MainWindow is not directly interactive, though being the top-level parent,
  # it does see keystrokes.
  def focusable?
    false
  end

  # MainWindow holds other controls so has no text of it's own.
  def text
    ""
  end

  def focus
    raise Exception.new("MainWindow can not be the active control")
  end

  # Sets focus to the nearest child/sibling control.
  def paint(term)
  end

  action def next_control
    ac = all_children.to_a
    cur = ac.index(active_control).not_nil!
idx=cur
while 1
    idx += 1
if idx==cur
@dirty=false
return
end
if idx==ac.size
idx=-1
next
end
next if ! ac[idx].focusable?
break
end
    self.active_control = ac[idx]
  end

  # exit the program.
  # Not named exit because that is a crystal kernel method.
  action def quit
    Log.info { "exitting" }
    exit
  end

  def run
    if children.size == 0
      raise Exception.new("main window must have children")
    end
    self.active_control = all_children.select { |i| i.focusable? }[0]
    react_to_keys
    handle_refresh
  end

  def handle_refresh
    spawn do
      while @refresh_channel.receive
        begin
          do_refresh
        rescue e
          Log.error { "error during do_refresh\n#{e.inspect_with_backtrace}" }
        end
      end # while
    end   # spawn
    sleep 0.seconds
  end # def

  def react_to_keys
    spawn do
      while 1
        t = @term.getkey
        begin
          handle_key t
        rescue e
          Log.error { "error during handle_key\n#{e.inspect_with_backtrace}" }
        end # rescue
      end   # while
    end     # spawn
    sleep 0.seconds
  end # def

  # modeled after bubbling events in web browsers.
  # Send the key to the currently active control, and continue sending it up the control's parents, so long as each control returns :continue.
  # If any control sets it's dirty flag, trigger a refresh.
  def handle_key(k)
    t = active_control
    Log.info { "handle_key #{k} active control #{t.class.name}" }
    need_refresh = true
    total = 0.seconds
    while c = t
      start = Time.monotonic
      rv = c.key k
      stop = Time.monotonic
      total += (stop - start)
#      Log.info { "#{c} dirty? #{c.dirty}" }
      need_refresh = true if c.dirty
      break if rv != :continue
      t = c.parent?
    end
    refresh if need_refresh
#    Log.info { "time #{total}" }
  end # def

  # Keys are processed in their own fiber.
  def read_keys
    tmp = Channel(Int32).new
    spawn do
      tmp.send 0
      while 1
        t = STDIN.read_byte.not_nil!
        @term.input_channel.send t
      end # while
    end   # spawn
    sleep 0.seconds
    tmp.receive
  end # def

  def all_children
    ret = [] of Control
    tmp = [] of Control
    tmp << self
    while tmp.size > 0
      t = tmp.delete_at(0)
      ret << t
      t.children.reverse_each do |c|
        tmp.insert 0, c
      end # each child
    end   # while tmp
    ret
  end

  def refresh
    @refresh_channel.send 0
  end

  # repaints the screen.
  def do_refresh
    all_children.each do |c|
      if !c.dirty
#        Log.info { "skipping refresh for #{c} because dirty is false" }
        next
      end # if
c.paint @term
      c.dirty = false
    end # each child
    loc = {active_control.y + active_control.user_y, active_control.x + active_control.user_x}
    Log.info { "moving to #{loc[0]},#{loc[1]} for #{active_control.class.name}" }
    @term.move y: loc[0], x: loc[1]
  end # def

end # class
