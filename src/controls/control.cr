def assert(v)
  if v != true
    raise Exception.new("assert failed")
  end
end

abstract class Control
  @parent : Control? = nil
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
  getter! width, height, x, y, parent
  property dirty
  setter x, y, width, height, parent
  getter children, user_x, user_y

  abstract def text

  abstract def key(k)
  # : String|Char|Symbol)

  abstract def focusable?

  def focus
    @dirty = true
  end

  # pass a child control to this method for verification
  def verify(control)
    # each of our children (c) must have
    # c.y>=@y
    assert control.y >= self.y
    # c.x>=@x
    assert control.x >= self.x
    # c.y+c.height<=@y+@height
    assert (control.y + control.height) <= (self.y + self.height)
    # c.x+c.width<=@x+@width
    assert (control.x + control.width) <= (self.x + self.width)
    # todo:
    # ensure control.x..control.x+control.width
    # and control.y..control.y+control.height
    # do not intersect any existing child controls
  end

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
    verify control
    control.parent = self
    @children << control
  end # def

end # class
