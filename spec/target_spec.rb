require 'rspec'

include Barmaid

describe 'Target' do
  before :each do
    @target = Target.new('test', 'server1')
  end

  describe "#new" do
    it 'should be an instance of Target object' do
      expect(@target).to be_an_instance_of Target
    end

    it 'should assign id' do
      expect(@target.id).to eq('test')
    end

    it 'should assign server_id' do
      expect(@target.server_id).to eq('server1')
    end

    it 'should initialize attributes from params hash' do
      @target = Target.new('test', 'server1', {:path => "/test" })
      expect(@target.id).to eq("test")
      expect(@target.server_id).to eq("server1")
      expect(@target.path).to eq("/test")
    end
  end

  describe "#parse_opts" do
    it 'should initialize attributes from params hash' do
      @target.parse_opts({:path => '/test', :remote_ssh_cmd => 'ssh', :recover_job_name => 'name1' })

      expect(@target.path).to eq('/test')
      expect(@target.remote_ssh_cmd).to eq('ssh')
      expect(@target.recover_job_name).to eq('name1')
    end
  end

end
