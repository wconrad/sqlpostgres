
shared_context "AllCharacters" do

  def self.allCharactersExceptNull
    allCharacters(1)
  end

  def self.allCharacters(floor = 0)
    s = (floor..255).to_a.collect do |i|
      i.chr
    end.join
    if s.respond_to?(:force_encoding)
      s = s.force_encoding('ASCII-8BIT')
    end
    s
  end

end
