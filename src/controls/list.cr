abstract class ListControl < Control
  @find_buffer = ""
  @last_key_time = Time.monotonic

  abstract def items : Iterable

  abstract def pos : Int32
  abstract def pos=(v : Int32)

  def focusable?
    true
  end

  action def list_down
    if pos + 1 == items.size
      @dirty = false
      return
    end
    self.pos += 1
    #    if user_y == 0
    #      return true
    #    end
  end

  action def list_up
    if pos == 0
      @dirty = false
      return
    end
    self.pos -= 1
    #    if user_y == height - 1
    #      return true
    #    end
  end

  def letter(k)
    t = Time.monotonic
    o = k[0].ord
    if 32 <= o <= 126
      if (t - @last_key_time) > (0.5).seconds
        @find_buffer = ""
      end # if
      @last_key_time = t
      @find_buffer += k
      find_from_buffer
    end
  end

  def find_from_buffer
    if items.size < 2
      @dirty = false
      return
    end
    t = pos
    while 1
      t += 1
      if t == pos
        break
      end
      if t >= items.size
        t = -1
        next
      end
      if items[t].to_s.starts_with?(@find_buffer)
        Log.info { "found #{items[t].to_s} starts with #{@find_buffer}" }
        old_pos = pos
        self.pos = t
        return
      end # if
    end   # while
  end     # def

  # might use this later to determine if screen (displayed chunk from items) has changed
  #        if (
  #             (old_pos//height + 1) !=
  #               (pos//height + 1)
  #           )
  # return
  #        else
  # @dirty=false
  #          return
  #        end

  def text
    start = (pos//height)*height
    stop = start + height
    Log.info { "displaying items #{start}...#{stop} #{items[start...stop]}" }
    items[start...stop].map(&.to_s).join("\n")
  end

  def user_y
    pos % height
  end

  def initialize(@height = nil, @width = nil)
  end
end # class
