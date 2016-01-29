require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Upstart::Exporter::ExpandedExporter do
  before do
    @defaults = {}
    Upstart::Exporter::Options::Global::DEFAULTS.each do |key, value|
      @defaults[key.to_sym] = value
    end

    allow(File).to receive(:open)
  end

  it 'calls template render exact amount of times' do
    expect(Upstart::Exporter::Templates).to receive(:command).exactly(5).times
    options = {
      :commands => {
        'commands' => {
          'ls' => {
            'command' => 'ls',
            'count' => 3
          },
          'ls2' => {
            'command' => 'ls',
            'count' => 2
          }
        }
      },
      :app_name => 'appname'
    }.merge(@defaults)

    described_class.export(options)
  end

  it 'merges env params in the right order' do
    expect(Upstart::Exporter::Templates).to receive(:helper) do |options|
      expect(options[:cmd]).to include('B=b')
      expect(options[:cmd]).to include('T=t')
    end
    options = {
      :commands => {
        'env' => {
          'T' => 't',
          'B' => 'a'
        },
        'commands' => {
          'ls' => {
            'command' => 'ls',
            'env' => {
              'B' => 'b'
            }
          }
        }
      },
      :app_name => 'appname'
    }.merge(@defaults)

    described_class.export(options)
  end

  it 'passes all calculated binds to the helper exporter' do
    options = {
      :version => 2,
      :app_name => 'appname',
      :working_directory => "/",
      :log => "public.log",
      :commands => {
        'working_directory' => '/var/log',
        'commands' => {
          'rm1' => {
            'command' => 'rm *',
            'log' => 'private.log'
          },
          'rm2' => {
            'command' => 'rm -rf *',
            'working_directory' => '/home'
          },
          'rm3' => {
            'command' => 'rm -f vmlinuz',
          }
        }
      }
    }.merge(@defaults)
    expect(Upstart::Exporter::Templates).to receive(:helper).with(hash_including(
      "working_directory"=>"/var/log",
      "log"=>"private.log",
      :cmd=>"cd '/var/log' && exec rm * >> private.log 2>&1"
    ))
    expect(Upstart::Exporter::Templates).to receive(:helper).with(hash_including(
      "working_directory"=>"/home",
      "log"=>"public.log",
      :cmd=>"cd '/home' && exec rm -rf * >> public.log 2>&1"
    ))
    expect(Upstart::Exporter::Templates).to receive(:helper).with(hash_including(
      "working_directory"=>"/var/log",
      "log"=>"public.log",
      :cmd=>"cd '/var/log' && exec rm -f vmlinuz >> public.log 2>&1"
    ))
    described_class.export(options)
  end
end
