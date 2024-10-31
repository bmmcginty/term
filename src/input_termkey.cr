require "../../libtermkey-cr/src/termkey"

module InputTermkey
  @tk : Termkey

  def getpos
    Log.info { "getpos" }
    reqpos
    s = Bytes.new size: 20
    idx = 0
    while 1
      s[idx] = input_channel.receive
      break if s[idx] == 'R'.ord
      if idx >= 19
        raise Exception.new("invalid characters received while requesting cursor position")
      end
      idx += 1
    end
    Log.info { "got s #{s}" }
    @tk << s[0]
    @tk << s[1]
    if s[2] != '?'.ord
      @tk << '?'.ord.to_u8
    end
    (2..idx).each do |i|
      t = s[i]
      @tk << t
    end
    res = @tk.getkey
    Log.info { "getpos got #{res}" }
    Log.info { "#{@tk.key}" }
    if !@tk.key.type.position?
      raise Exception.new("got text while requesting screen dementions")
    end # if text interleaved with position
    res, line, col = @tk.getpos
    Log.info { "dims res #{res} line #{line} col #{col}" }
    {line, col}
  end

  def getkey
    ts1 = nil
    while 1
      @tk << input_channel.receive
      ts1 = ts1 ? ts1 : Time.monotonic
      res = @tk.getkey
      next if res.again?
      break if res.key?
      raise Exception.new("unknown #{res.to_s}")
    end # while
    ts2 = Time.monotonic
    ret = @tk.strfkey
    ts3 = Time.monotonic
    Log.info { "key read time #{ts2 - ts1.not_nil!}" }
    Log.info { "key strf time #{ts3 - ts2}" }
    ret
  end # def

end # module
