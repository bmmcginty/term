require "../src/log"
require "../src/controls/*"


class KeyControl < StaticTextControl
def key(k)
if k.is_a?(Char) && k.as(Char).ord==17
return :continue
end
@dirty=true
pr=parent.as(MainWindow).unprocessable
if k==:special
k=pr.pop
pr.clear
end
@text=k.inspect
parent.as(MainWindow).refresh
end # def
end # class

a=MainWindow.new
edit=KeyControl.new height: 1, text: ""
a.add edit
a.run
a.refresh
sleep
