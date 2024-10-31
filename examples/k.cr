require "../src/log"
require "../src/controls/*"

class KeyControl < StaticTextControl
  action def quit
    :continue
  end

  def letter(k)
    other(k)
  end

  def other(k)
    @text = "#{k.inspect}#{k.is_a?(Char) ? k.ord : ""}"
  end # def

end # class

a = MainWindow.new
edit = KeyControl.new height: 1, text: ""
a.add edit
a.run
sleep
