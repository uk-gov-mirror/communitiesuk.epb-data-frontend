describe Helper::Form do
  subject(:form_helper) { described_class }

  describe "#has_tag?" do
    it "return true when there are html tags in the string" do
      string = "<h1>Testy McTest</h1>"
      expect(form_helper.has_tag?(string)).to be true
    end

    it "return true when there are js tags in a string" do
      string = "<img src=x onerror=alert(1)>Text"
      expect(form_helper.has_tag?(string)).to be true
    end

    it "returns true when the tag is broken" do
      string = "<img src=http://cataas.com/cat"
      expect(form_helper.has_tag?(string)).to be true
    end

    it "return false when there are no tags in a string" do
      string = "Text?"
      expect(form_helper.has_tag?(string)).to be false
    end
  end
end
