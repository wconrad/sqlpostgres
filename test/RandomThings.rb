module RandomThings

  def randomString
    rand.to_s
  end
  module_function :randomString

  alias_method :randomWhatever, :randomString
  module_function :randomWhatever

  def randomInteger
    rand(1000000)
  end

  def randomFloat
    rand
  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
