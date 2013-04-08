require 'rspec'

include Barmaid

describe 'ShellCommand' do

  before :each do
    @cmd = ShellCommand.new('test')
  end

  describe "#new" do
    it 'should be an instance of ShellCommand object' do
      expect(@cmd).to be_an_instance_of ShellCommand
    end
  end

  describe "#exec_local" do
    it 'should call Mixlib::ShellOut with assigned command' do
      Mixlib::ShellOut.any_instance.stub(:run_command)
      @cmd.cmd = "/bin/true"
      Mixlib::ShellOut.any_instance.should_receive(:initialize).with(@cmd.cmd)
      @cmd.exec_local
    end
  end

end
