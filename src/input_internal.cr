# No longer used.
# Left in case libterm causes problems.
module InputInternal
  def getkey
    t = input_channel.receive
    if t != 27
      return read_utf8 t
    end
    spc = read_special t
    if spc.is_a?(Symbol)
      return spc
    end
    tag = key_to_uint64(spc.as(String))
    if @keys[tag]?
      @keys[tag]
    else
      @unprocessable << spc.as(String)
      :special
    end
  end

  def read_utf8(byte)
    seen = 1
    length, code = if byte < 128
                     {1, byte.to_u32}
                   elsif (byte >> 5) == 0b110
                     {2, (byte & 0b11111).to_u32}
                   elsif (byte >> 4) == 0b1110
                     {3, (byte & 0b1111).to_u32}
                   elsif (byte >> 3) == 0b11110
                     {4, (byte & 0b111).to_u32}
                   else
                     raise Exception.new("invalid length for unicode")
                   end
    while seen < length
      byte = input_channel.receive
      code = (code << 6) + (byte & 0b111111)
      seen += 1
    end
    code.chr
  end

  def read_special(first_byte)
    byte = nil
    select
    when t = input_channel.receive
      Log.info { "got t #{t}  after first byte #{first_byte}" }
      byte = t
    when timeout((0.1).seconds)
      Log.info { "timeout after escape" }
    end
    if byte == nil
      Log.info { "got nil byte" }
      return :escape
    end
    byte = byte.not_nil!
    if byte == '['.ord
      read_special_csi byte
    elsif byte == ']'.ord || byte == 'X'.ord
      read_special_terminated byte
    elsif byte == 27
      Log.info { "second byte 27, escape" }
      :escape
    elsif byte == 'O'.ord
      select
      when t = input_channel.receive
        @unprocessable << "O#{t.chr}"
      when timeout((0.1).seconds)
        @unprocessable << "O"
      end
      :special
    else
      @unprocessable << "#{first_byte.chr}#{byte.chr}"
      :special
    end
  end

  def read_special_csi(type)
    # log "read_special_csi"
    # type will == '['.ord
    pos = -1
    out = ""
    out += type.chr
    while t = input_channel.receive
      pos += 1
      out += t.chr
      if 0x40 <= t <= 0x7e
        break
      end # if
    end   # while
    out
  end # def

  def read_special_terminated(byte)
    # log "read_special_terminated"
    out = ""
    out += byte.chr
    while t = input_channel.receive
      out += byte.chr
      # terminate on \e\ (esc backslash)
      if out.ends_with?(esc + "\\")
        out = out[0..-2]
        break
      end
    end
    out
  end

  # turns a multi-byte key sequence into an uint64
  def key_to_uint64(s)
    t = 0_u64
    s.each_char do |char|
      t = t << 8
      t += char.ord
    end
    t
  end

  # assign keys from an array to the @keys hash
  def set_keymap(l)
    idx = 0
    while idx + 1 < l.size
      @keys[key_to_uint64(l[idx].as(String))] = l[idx + 1].as(Symbol)
      idx += 2
    end
  end

  def set_default_keys
    set_keymap [
      "[\u00FF", :unknown,
      "[D", :left,
      "[H", :home,
      "[B", :down,
      "[C", :right,
      "[A", :up,
      "[M", :f1,
      "[N", :f2,
      "[O", :f3,
      "[P", :f4,
      "[Q", :f5,
      "[R", :f6,
      "[S", :f7,
      "[T", :f8,
      "[U", :f9,
      "[V", :f10,
      "[W", :f11,
      "[X", :f12,
    ]
  end

  def getpos
    t = getkey
    if t != :special
      raise Exception.new("no response received for curpos")
    end
    s = @unprocessable.delete_at 0
    s = s[1..-2]
    s.split(";").map &.to_i
  end
end
