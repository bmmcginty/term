abstract class ListControl < Control
  @find_buffer = ""
  @last_key_time = Time.monotonic

  abstract def items : Iterable

  abstract def pos : Int32
  abstract def pos=(v : Int32)

  def focusable?
    true
  end

  def next_item
    return false if pos + 1 == items.size
    self.pos += 1
    if user_y == 0
      return true
    end
  end

  def prev_item
    return false if pos == 0
    self.pos -= 1
    if user_y == height - 1
      return true
    end
  end

  def find_from_buffer
    if items.size < 2
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
        if (
             (old_pos//height + 1) !=
               (pos//height + 1)
           )
          return true
        else
          return false
        end
      end # if
    end   # while
    nil
  end # def

  def key(k)
    t = Time.monotonic
    refresh = false
    case k
    when :down
      refresh = next_item
    when :up
      refresh = prev_item
    when Char
      o = k.ord
      if 32 <= o <= 126
        if (t - @last_key_time) > (0.5).seconds
          @find_buffer = ""
        end # if
        @last_key_time = t
        @find_buffer += k
        refresh = find_from_buffer
      else
        return :continue
      end # if find
    else
      return :continue
    end # case
    if refresh
      @dirty = true
    end
    parent.as(MainWindow).refresh
  end

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
