# Throws an error if the passed-in result is false
def assert(v, msg = "assert failed")
  if v != true
    raise Exception.new(msg)
  end
end

# proc for holding an action dispatcher
alias ActionRunner = Proc(Control, Symbol | Nil)

abstract class Control
  # children directly inside this one
  # a child can take up the entirety of this controls space
  @children = [] of Control
  # how many rows we are
  @height : Int32? = nil
  # how many columns we are
  @width : Int32? = nil
  # our vertical position on the terminal
  @y = 0
  # our horizontal position on the terminal
  @x = 0
  # our position inside the control, relative to the top left corner of the control
  # not based on absolute screen coordinates like the other measurements
  @user_y = 0
  @user_x = 0
  # does this control need repainting?
  @dirty = true
  property! width, height, x, y, parent, main_window
  property dirty
  getter children, user_x, user_y
  @@name_to_action = Hash(String, ActionRunner).new
  @key_to_action = Hash(String, ActionRunner).new
  @parent : Control?
  @main_window : MainWindow?

  # should return the text to be painted to the screen
  abstract def text

  # if this control can take keyboard input
  # Only frames, screens, and non-interactive elements should return false.
  abstract def focusable?

  def self.name_to_action
    @@name_to_action
  end

  # by default, key assumes any key press will cause the control to change state.
  # If you e.g. are at the top of a list, and attempt a prev_item action,
  # the code for prev_action must explicitly set @dirty to false
  # to prevent extraneous repaints.
  # This is purposefully done for developer productivity.
  def key(k)
    Log.info { "dispatching #{k} to #{self}" }
    @dirty = true
    f = @key_to_action[k]?
    ret = if f
            Log.info { "k #{k} binding #{f}" }
            f.call(self)
          elsif k.size == 1
            Log.info { "letter #{k}" }
            letter k
          elsif k == "space"
            Log.info { "letter space" }
            letter " "
          else
            Log.info { "k #{k} is other" }
            other k
          end # if
    Log.info { "got ret #{ret}" }
    ret
  end

  # processes space and any printable character.
  def letter(k)
    @dirty = false
    :continue
  end

  # handles keystrokes that aren't explicitly bound.
  def other(k)
    @dirty = false
    :continue
  end

  # called when this control becomes the active control.
  # It will start receiving keystrokes after this point.
  def focus
    @dirty = true
  end

  # pass a child control to this method for verification
  def verify(child)
    # each of our children (c) must have
    # c.y>=@y
    assert child.y >= self.y
    # c.x>=@x
    assert child.x >= self.x
    # c.y+c.height<=@y+@height
    assert (child.y + child.height) <= (self.y + self.height)
    # c.x+c.width<=@x+@width
    assert (child.x + child.width) <= (self.x + self.width)
    # todo:
    # ensure control.x..control.x+control.width
    # and control.y..control.y+control.height
    # do not intersect any existing child controls
  end

  # will verify that none of the four corners of new child overlap with an existing child,
  # and that no existing child overlaps any of it's 4 corners with new child.
  def wip_verify_no_overlap
    all_children.each do |i|
      min_x = i.x
      min_y = i.y
      max_x = min_x + i.width
      max_y = i.y + i.height
      points = [{child.x, child.y}, {child.x + child.width, child.y},
                {child.x + child.width, child.y},
                {child.x + child.width, child.y + child.height}]
    end # each
  end   # def

  # Makes control a child of this one.
  def add(control, x = 0, y = 0)
    Log.info { "add control #{control}" }
    control.x = @x + x
    control.y = @y + y
    Log.info { "control.width #{control.width?.inspect} self width #{@width.inspect}" }
    if !control.width?
      control.width = @width
    end
    if !control.height?
      control.height = @height
    end
    control.main_window = self.main_window
    control.parent = self
    verify control
    control.bind_keys
    @children << control
  end # def

  # For each bindable function, aka action,
  # if that action exists in the keymap,
  # associate the keymap's key with that action for this specific control.
  def bind_keys
    p = self
    while p.parent?
      p = p.parent
    end
    keys = p.as(MainWindow).keys
    Log.info { "self #{self} keys #{keys} self #{@@name_to_action}" }
    keys.each do |k, vl|
      vl.each do |v|
        m = @@name_to_action[v]?
        if m
          @key_to_action[k] = m
        end # if m
        break
      end # each vl
    end   # each v
  end     # def

  # writing action def name... creates an action that can be bound to a key
  # we have this macro include itself again below
  # so that the action gets copy-and-pasted to each subclass.
  # because class vars aren't singletons,
  # subclassing a control removes all action bindings from the subclassed control by default.
  # This undo's that removal.
  macro action(func)
macro inherited
action {{func}}
end
@@name_to_action[{{func.name.stringify}}]=ActionRunner.new do |cls|
rv=cls.as({{@type.name}}).{{func.name}}
rv==:continue ? :continue : nil
end# proc
{{func}}
end
end # class
