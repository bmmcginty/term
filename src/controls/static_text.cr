require "./control"

class StaticTextControl < Control
  @text : String
@focusable : Bool

  getter text

  def text=(@text)
    @dirty = true
  end # def

  def initialize(@text, @height = nil, @width = nil, @focusable=true)
  end

  def focusable?
    @focusable
  end
end # class
