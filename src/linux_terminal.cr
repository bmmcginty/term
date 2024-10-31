require "./terminal"
require "./fix"
require "./input_termkey"
require "./log"

class LinuxTerminal < Terminal
  @tty : IO::FileDescriptor
  getter! input_channel, tty

  include InputTermkey

  def initialize
    @tty = STDOUT
    tty.raw!
    tty.noecho!
    #    set_default_keys
    @tk = Termkey.new ENV["TERM"]
  end

  def run
    # get size
    size
    clear
    top
  end

  def done
    clear
    tty.cooked!
    tty.echo!
  end

  def top
    move 0, 0
  end

  def bottom
    move @maxy, 0
  end

  def title(s)
    send esc, osc, "0;#{s}", esc, oscts
  end

  def move(y, x)
    send esc, csi, "#{y + 1};#{x + 1}H"
  end

  def clear
    send esc, csi, "2J"
  end

  def reqpos
    send esc, csi, "6n"
  end

  def size
    if @init
      return {x: @maxx, y: @maxy}
    end
    move 1000, 1000
    Log.info { "doing getpos from size from run" }
    y, x = getpos
    move 0, 0
    @init = true
    @maxy = y - 1
    @maxx = x - 1
    return {x: @maxx, y: @maxy}
  end

  def write(text)
    tty << text
  end

  def up
    send esc, "EM"
  end

  def down
    send '\n'
  end

  def esc
    '\u001b'
  end

  def csi
    '['
  end

  def osc
    ']'
  end

  def oscts
    '\\'
  end

  def send(*things)
    tty << things.map(&.to_s).join("")
  end
end
