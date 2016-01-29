require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Upstart::Exporter::Errors do
  context "when included" do
    it "should provide #error method" do
      class Foo
        include Upstart::Exporter::Errors
      end

      expect(Foo.new).to respond_to(:error)
    end
  end

  describe "#error" do
    it "should raise a correct exception" do
      class Foo
        include Upstart::Exporter::Errors
      end

      expect{ Foo.new.error("arrgh") }.to raise_exception(Upstart::Exporter::Error)
    end
  end
end
