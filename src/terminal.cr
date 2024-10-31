class LoggingChannel < Channel(UInt8)
  def receive
    t = super
    Log.info { "receive #{t}" }
    t
  end
end

abstract class Terminal
  @init = false
  @input_channel = LoggingChannel.new
  @keys = Hash(UInt64, Symbol).new
  @maxy : Int32? = nil
  @maxx : Int32? = nil
  @unprocessable = [] of String

  getter! maxy, maxx
  # todo: remove in favor of #key and #special
  getter unprocessable

  abstract def move(y : Int32, x : Int32)
  abstract def write(text : String)
  abstract def clear
end
