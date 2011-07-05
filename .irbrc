class Object
  def omethods
    self.methods - Object.methods
  end
end
# vim:expandtab:
