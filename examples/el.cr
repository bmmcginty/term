require "../src/log"
require "../src/controls/edit"
require "../src/controls/main_window"

class CustomEditControl < EditControl
  action def backspace
    super
  end
end

a = MainWindow.new
edit = CustomEditControl.new height: 1, text: "abcdefg", width: 3
a.add edit, y: 0
a.run
a.refresh
sleep
