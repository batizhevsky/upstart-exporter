require_relative '../../../spec_helper'

describe Upstart::Exporter::Options::CommandLine do
  context "when correct options are given" do
    it "should give access to options like a hash" do
        make_procfile('Procfile', 'ls_cmd: ls')
        expect(described_class.new(:app_name => 'someappname', :procfile => 'Procfile')).to respond_to('[]')
    end

    it "should parse procfile" do
        make_procfile('Procfile', 'ls_cmd: ls')
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        expect(options[:commands]).to eq({'ls_cmd' => ' ls'})
    end

    it 'should parse procfile v2' do
        make_procfile('Procfile', "version: 2\ncommands:\n  ls:\n    command: ls -al")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        expect(options[:commands]).to have_key('commands')
        expect(options[:commands]['commands']).to have_key('ls')
    end

    it "should skip empty and commented lines in a procfile" do
        make_procfile('Procfile', "ls_cmd1: ls1\n\nls_cmd2: ls2\n # fooo baaar")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        expect(options[:commands]).to eq({'ls_cmd1' => ' ls1', 'ls_cmd2' => ' ls2'})
    end

    it "should store app_name" do
        make_procfile('Procfile', "ls_cmd1: ls1\n\nls_cmd2: ls2\n # fooo baaar")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile')
        expect(options[:app_name]).to eq('someappname')
    end

    it "should not process procfile if :clear arg is present" do
        make_procfile('Procfile', "bad procfile")
        options = described_class.new(:app_name => 'someappname', :procfile => 'Procfile', :clear => true)
        expect(options[:app_name]).to eq('someappname')
        expect(options[:commands]).to eq({})
    end
  end

  context "when bad app_name is passed" do
    it "should raise exception" do
      make_procfile('Procfile', 'ls_cmd: ls')
      expect{ described_class.new(:app_name => 'some appname', :procfile => 'Procfile') }.to raise_exception
      expect{ described_class.new(:app_name => '-someappname', :procfile => 'Procfile') }.to raise_exception
      expect{ described_class.new(:procfile => 'Procfile') }.to raise_exception
    end
  end

  context "when bad Procfile is passed" do
    it "should raise exception" do
      make_procfile('Procfile', 'ls cmd: ls')
      expect{ described_class.new(:app_name => 'someappname', :procfile => 'Procfile') }.to raise_exception

      make_procfile('Procfile', '-lscmd: ls')
      expect{ described_class.new(:app_name => 'someappname', :procfile => 'Procfile') }.to raise_exception

      expect{ described_class.new(:app_name => 'someappname', :procfile => '::') }.to raise_exception

      make_procfile('Procfile', "version: 2\ncommands:\n  ls cmd:\n    command: ls")
      expect{ described_class.new(:app_name => 'someappname', :procfile => 'Procfile') }.to raise_exception

      expect{ described_class.new(:app_name => 'someappname') }.to raise_exception
    end
  end


end

