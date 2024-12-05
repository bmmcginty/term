require "./static_text"

class EditControl < Control
  @text : Array(String)
  @pos = 0
  @focusable : Bool

  def focusable?
    @focusable
  end

  def text=(s : String)
    @text = s.split("")
  end

  action def next_char
    @pos += 1
    if @pos > @text.size
      @pos = @text.size
      @dirty = false
    end
  end

  action def prev_char
    @pos -= 1
    if @pos < 0
      @dirty = false
      @pos = 0
    end
    Log.info { "prev_char called, pos #{@pos}, dirty #{@dirty}" }
  end

  def letter(k)
    st = Time.monotonic
    insert k
    et = Time.monotonic
    Log.info { "control insert time #{et - st}" }
  end

  def insert(t)
    #    tmp = @text.split("")
    @text.insert @pos, t
    @pos += 1
    #    @text = tmp.join("")
  end

  action def backspace
    if @pos == 0
      @dirty = false
      return
    end
    @text.delete_at @pos - 1
    @pos -= 1
  end

  def user_x
    # chunk=@pos/width
    @pos % width
  end

  def text
    w = width
    # chunks will be zero based (0 for 0-39, 1 for 40-79, ...)
    if @text.size <= w
      return @text.join("")
    end
    start = 0
    stop = w
    while !(start <= @pos < stop)
      start += w
      stop += w
    end
    @text[start...stop].join("")
  end

  def initialize(text, @height = nil, @width = nil, @focusable = true)
    @text = Array(String).new initial_capacity: 1024*1024
    @text.concat text.split("")
  end # def

end # class
