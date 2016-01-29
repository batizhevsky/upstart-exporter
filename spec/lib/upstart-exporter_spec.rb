require_relative '../spec_helper'

describe Upstart::Exporter do
  let(:tpl){ Upstart::Exporter::Templates }

  before do
    make_global_config({
      'helper_dir' => '/h',
      'upstart_dir' => '/u',
      'run_user' => 'u',
      'run_group' => 'g',
      'prefix' => 'p-',
      'start_on_runlevel' => '[7]',
      'respawn' => {
        'count' => 7,
        'interval' => 14
      }
    }.to_yaml)
    make_procfile('Procfile', 'ls_cmd: ls')
  end

  let(:exporter) do
    exporter = described_class.new({:app_name => 'app', :procfile => 'Procfile'})
  end

  describe '#export v2' do
    it 'should correctly set respawn option' do

      yaml = <<-eos
version: 2
commands:
  first_cmd:
    command: ping 127.0.0.1
    respawn:
      count: 9
      interval: 19
  second_cmd:
    command: ping 127.0.0.1
    respawn: false
  third_cmd:
    command: ping 127.0.0.1
      eos
      make_procfile('Procfile', yaml)

      exporter.export
      expect(File.read('/u/p-app-first_cmd.conf')).to include("respawn\nrespawn limit 9 19")
      expect(File.read('/u/p-app-second_cmd.conf')).not_to include("respawn")
      expect(File.read('/u/p-app-third_cmd.conf')).to include("respawn\nrespawn limit 7 14")
    end
  end

  describe '#export' do
    it 'should make cleanup before export' do
      expect(exporter).to receive(:clear)
      exporter.export
    end

    it 'should create upstart scripts, folders and sh helpers' do
      exporter.export
      %w{/h/p-app-ls_cmd.sh /u/p-app.conf /u/p-app-ls_cmd.conf}.each do |f|
        expect(FileTest.file?(f)).to eq(true)
      end
    end

    it 'created scripts, folders and sh helpers should have valid content' do
      exporter.export

      expect(File.read('/h/p-app-ls_cmd.sh')).to eq(tpl.helper(:cmd => 'exec ls'))
      expect(File.read('/u/p-app.conf')).to eq(tpl.app(:run_user => 'u',
                                                   :run_group => 'g',
                                                   :app_name => 'p-app',
                                                   :start_on => 'runlevel [7]',
                                                   :stop_on => 'runlevel [3]'))
      expect(File.read('/u/p-app-ls_cmd.conf')).to eq(tpl.command(:run_user => 'u',
                                                              :run_group => 'g',
                                                              :app_name => 'p-app',
                                                              :cmd_name => 'ls_cmd',
                                                              :start_on => 'starting p-app',
                                                              :stop_on => 'stopping p-app',
                                                              :respawn => 'respawn',
                                                              :respawn_limit => 'respawn limit 7 14',
                                                              :kill_timeout => 30,
                                                              :helper_cmd_conf => '/h/p-app-ls_cmd.sh'))
    end

    it 'prepends with "env" command starts with env var assignment' do
      make_procfile('Procfile', 'sidekiq: RAILS_ENV=production sidekiq')
      exporter.export

      expect(File.read('/h/p-app-sidekiq.sh')).to eq(tpl.helper(:cmd => 'exec env RAILS_ENV=production sidekiq'))
    end

    it 'call to "env" will not appear twice' do
      make_procfile('Procfile', 'sidekiq: env RAILS_ENV=production sidekiq')
      exporter.export

      expect(File.read('/h/p-app-sidekiq.sh')).to eq(tpl.helper(:cmd => 'exec env RAILS_ENV=production sidekiq'))
    end
  end

  describe '#clear' do
    it 'should remove exported app helpers an scripts' do
      exporter.export
      exporter.clear
      expect(Dir['/h/*']).to be_empty
      expect(Dir['/u/*']).to be_empty
    end

    it 'should keep files of other apps' do
      exporter.export

      make_procfile('Procfile1', 'ls_cmd: ls')
      other_exporter = described_class.new({:app_name => 'other_app', :procfile => 'Procfile1'})
      other_exporter.export

      exporter.clear

      %w{/h/p-other_app-ls_cmd.sh /u/p-other_app.conf /u/p-other_app-ls_cmd.conf}.each do |f|
        expect(FileTest.file?(f)).to eql true
      end
    end
  end

end

