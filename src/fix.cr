class IO::FileDescriptor < IO
  def noecho! : Nil
    system_echo!(false) { return }
  end

  def echo! : Nil
    system_echo!(true) { return }
  end

  def cooked! : Nil
    system_raw!(false) { return }
  end

  def raw! : Nil
    system_raw!(true) { return }
  end
end

module Crystal::System::FileDescriptor
  private def system_console_mode!(&)
    before = FileDescriptor.tcgetattr(fd)
    begin
      yield before
    end
  end

  private def system_echo!(enable : Bool, & : ->)
    system_console_mode! do |mode|
      flags = LibC::ECHO | LibC::ECHOE | LibC::ECHOK | LibC::ECHONL
      mode.c_lflag = enable ? (mode.c_lflag | flags) : (mode.c_lflag & ~flags)
      if FileDescriptor.tcsetattr(fd, LibC::TCSANOW, pointerof(mode)) != 0
        raise IO::Error.from_errno("tcsetattr")
      end
      yield
    end
  end

  private def system_raw!(enable : Bool, & : ->)
    system_console_mode! do |mode|
      if enable
        mode = FileDescriptor.cfmakeraw(mode)
      else
        mode.c_iflag |= LibC::BRKINT | LibC::ISTRIP | LibC::ICRNL | LibC::IXON
        mode.c_oflag |= LibC::OPOST
        mode.c_lflag |= LibC::ECHO | LibC::ECHOE | LibC::ECHOK | LibC::ECHONL | LibC::ICANON | LibC::ISIG | LibC::IEXTEN
      end
      if FileDescriptor.tcsetattr(fd, LibC::TCSANOW, pointerof(mode)) != 0
        raise IO::Error.from_errno("tcsetattr")
      end
      yield
    end
  end
end
