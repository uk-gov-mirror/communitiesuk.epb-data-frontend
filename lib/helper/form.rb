module Helper
  class Form
    def self.has_tag?(str)
      str.match?(/[<>]/)
    end
  end
end
