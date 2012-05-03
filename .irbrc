require 'pp'
class Object
  def omethods
    self.methods - Object.methods
  end
end
load File.expand_path("~/.irbrc_adaptly")
# vim:expandtab:
