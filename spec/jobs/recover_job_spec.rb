require 'spec_helper'

include Barmaid::Job

describe RecoverJob do
  before :each do
    uuid = SecureRandom.hex.to_s
    @job = RecoverJob.new(uuid, {})
    Barmaid::Logger.log('RecoverJob').outputters = nil
  end

  describe "#new" do
    it 'should be an instance of a RecoverJob object' do
      expect(@job).to be_an_instance_of RecoverJob
    end

    it 'should assign parameters to attributes' do
      backup = RBarman::Backup.new
      backup.server = '123'
      @job = RecoverJob.new(nil)
      @job.backup = backup
      @job.path = '/home'
      @job.recover_opts = { :test => 123}
      expect(@job.backup.server).to eq('123')
      expect(@job.path).to eq('/home')
      expect(@job.recover_opts[:test]).to eq(123)
    end
  end

  describe "#execute" do
    it 'should call before_recover, recover and after_recover' do
      @job.backup = RBarman::Backup.new
      @job.stub!(:recover)
      @job.stub!(:completed)
      @job.should_receive(:before_recover)
      @job.should_receive(:recover)
      @job.should_receive(:after_recover)
      @job.execute
    end
  end

  describe "#remote_recover?" do
    it 'should return true when recover_opts[:remote_ssh_cmd] is set, otherwise false' do
      @job.recover_opts[:remote_ssh_cmd] = 'ssh postgres@localhost'
      expect(@job.remote_recover?).to eq(true)
      @job.recover_opts = nil
      expect(@job.remote_recover?).to eq(false)
    end
  end

  describe "#target_path_disk_usage" do
    it 'should return target path disk usage in bytes' do
      res = ShellCommand::ShellCommandResult.new("a", "22756856\t/usr/local\n", "", 0)
      @job.stub!(:exec_command).and_return(res)
      expect(@job.target_path_disk_usage).to eq(22756856)
    end
  end

  describe "#target_path_exists?" do
    it 'should return true if path exists' do
      res = ShellCommand::ShellCommandResult.new("a", "","", 0)
      @job.stub!(:exec_command).and_return(res)
      expect(@job.target_path_exists?).to eq(true)
    end
    it 'should return false if path does not exist' do
      res = ShellCommand::ShellCommandResult.new("a", "","", 1)
      @job.stub!(:exec_command).and_return(res)
      expect(@job.target_path_exists?).to eq(false)
    end
  end

  describe ".create_job_by_configuration" do

    it 'should create a RecoverJob' do
      config = { :servers => 
        {
          :test1 => {
            :targets => {
              :ssh_localhost => {
                :path => "/var/test",
                :remote_ssh_cmd => "ssh postgres@127.0.0.1"
              }
            }
          }
        }
      }
      uuid = SecureRandom.hex.to_s
      Barmaid::Config.config = config
      RecoverJob.any_instance.should_receive(:assign_backup).with("test1", "20130325T060315")
      job = RecoverJob.create_job_by_configuration(uuid,{:server => "test1", :target => "ssh_localhost", :backup_id => "20130325T060315"})
      expect(job).to be_an_instance_of RecoverJob
      expect(job.recover_opts[:remote_ssh_cmd]).to eq('ssh postgres@127.0.0.1')
      expect(job.path).to eq("/var/test")
      expect(job.uuid).to eq(uuid)
    end

    it 'should create a RecoverJob#2' do
      config = { :servers => 
        {
          :test1 => {
            :targets => {
              :ssh_localhost => {
                :path => "/var/test",
                :remote_ssh_cmd => "ssh postgres@127.0.0.1"
              }
            }
          }
        }
      }
      params = {:server => "test1",
        :target => "ssh_localhost",
        :backup_id => "20130325T060315",
        :recover_opts => { :remote_ssh_cmd => "ssh postgres@123.0.0.2",
          :target_time => "123"
        }
      }
      uuid = SecureRandom.hex.to_s
      Barmaid::Config.config = config
      RecoverJob.any_instance.should_receive(:assign_backup).with("test1", "20130325T060315")
      job = RecoverJob.create_job_by_configuration(uuid,params)
      expect(job.recover_opts[:remote_ssh_cmd]).to eq('ssh postgres@127.0.0.1')
      expect(job.recover_opts[:target_time]).to eq('123')
    end

    it 'should create a TestRecoverJob' do
      config = { :servers => 
        {
          :test1 => {
            :targets => {
              :ssh_localhost => {
                :path => "/var/test",
                :recover_job_name => "TestRecoverJob"
              }
            }
          }
        }
      }
      uuid = SecureRandom.hex.to_s
      Barmaid::Config.config = config
      RecoverJob.any_instance.should_receive(:assign_backup).with("test1", "20130325T060315")
      Object.const_set("TestRecoverJob", Class.new(RecoverJob))
      job = RecoverJob.create_job_by_configuration(uuid,{:server => "test1", :target => "ssh_localhost", :backup_id => "20130325T060315"})
      expect(job).to be_an_instance_of TestRecoverJob
    end


    it 'should raise an exception if no server is configured' do
      Barmaid::Config.config = {}
      expect{RecoverJob.create_job_by_configuration({:server => "test1"},nil)}.to raise_error
    end
  end

  describe "#ssh_session_valid?" do
    it 'should return false if ssh_session is null' do
      expect(@job.ssh_session_valid?).to eq(false)
    end

    it 'should return false if ssh_session is closed' do
      transport =  Object.new
      transport.stub!(:socket)
      transport.stub!(:logger).and_return(RecoverJob.logger)
      transport.stub!(:closed?).and_return(true)
      session = Net::SSH::Connection::Session.new(transport)
      @job.ssh_session = session
      expect(@job.ssh_session_valid?).to eq(false)
    end

    it 'should return true if ssh_session is not close' do
      transport =  Object.new
      transport.stub!(:socket)
      transport.stub!(:logger).and_return(RecoverJob.logger)
      transport.stub!(:closed?).and_return(false)
      session = Net::SSH::Connection::Session.new(transport)
      @job.ssh_session = session
      expect(@job.ssh_session_valid?).to eq(true)
    end
  end
end
