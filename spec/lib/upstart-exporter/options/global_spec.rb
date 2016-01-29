require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

describe Upstart::Exporter::Options::Global do
  let(:defaults){ Upstart::Exporter::Options::Global::DEFAULTS }
  let(:conf){ Upstart::Exporter::Options::Global::CONF }


  it "should give access to options like a hash" do
    capture(:stderr) do
      expect(described_class.new).to respond_to('[]')
    end
  end

  context "when no config present" do

    it "should provide default options" do
      capture(:stderr) do
        options = described_class.new
        defaults.each do |option, default_value|
          expect(options[option.to_sym]).to eq(default_value)
        end
      end
    end

  end

  context "when invalid config is given" do
    it "should raise exception" do
      make_global_config('zxc')
      expect{described_class.new}.to raise_exception
      make_global_config([123].to_yaml)
      expect{described_class.new}.to raise_exception
    end
  end

  context "when a valid config is given" do
    it "should override default values" do
      capture(:stderr) do
        make_global_config({'run_user' => 'wwwww'}.to_yaml)
        expect(described_class.new[:run_user]).to eq('wwwww')
      end
    end

    it "should preserve default values for options not specified in the config" do
      capture(:stderr) do
        make_global_config({'run_user' => 'wwwww'}.to_yaml)
        described_class.new[:prefix] == defaults['prefix']
      end
    end
  end

end
