require 'rspec'

include RBarman

describe 'Server' do
  before :each do
    @server = Server.new('backup1')
  end

  describe "#new" do
    it 'should be an instance of RBarman::Server object' do
      expect(@server).to be_an_instance_of RBarman::Server
    end
  end

  describe "#id" do
    it 'should return the name of the server' do
      expect(@server.id).to eq(@server.name)
    end
  end

  describe "#add_targets" do
    it 'should throw no error if no configuration exists' do
      Barmaid::Config.config[:servers] = {}
      @server.add_targets
      expect(@server.targets).to eq(nil)
    end

    it 'should throw no error if no target is configured' do
      Barmaid::Config.config[:servers] = {:backup_1 => {} }
      @server.add_targets
      expect(@server.targets).to eq(nil)
    end

    it 'should assign targets' do
      Barmaid::Config.config[:servers] = {
        :backup1 => {
          :targets => {
            :localhost => {
              :path => "/path"
            },
            :host2 => {
              :path => "/path2"
            }
          }
        }
      }
      @server.add_targets
      expect(@server.targets.count).to eq(2)
      expect(@server.targets[0].id).to eq("localhost")
      expect(@server.targets[0].server_id).to eq("backup1")
      expect(@server.targets[1].path).to eq("/path2")
    end
  end
end

