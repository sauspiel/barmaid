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

  describe "execute" do
    it 'should call before_recover, recover and after_recover' do
      @job.backup = RBarman::Backup.new
      @job.should_receive(:before_recover)
      @job.should_receive(:recover)
      @job.should_receive(:after_recover)
      @job.execute
    end
  end

  describe "execute" do
    it 'should call recover on Backup' do
      backup = RBarman::Backup.new
      @job.backup = backup
      @job.recover_opts = { :test => 123 }
      @job.path = '/home'
      RBarman::Backup.any_instance.should_receive(:recover).once.with(
        @job.path, @job.recover_opts)
      @job.execute
    end
  end

  describe "remote_recover?" do
    it 'should return true when recover_opts[:remote_ssh_cmd] is set, otherwise false' do
      @job.recover_opts[:remote_ssh_cmd] = 'ssh postgres@localhost'
      expect(@job.remote_recover?).to eq(true)
      @job.recover_opts = nil
      expect(@job.remote_recover?).to eq(false)
    end
  end

  describe "target_path_disk_usage" do
    it 'should return target path disk usage in bytes' do
      Mixlib::ShellOut.any_instance.stub(:run_command)
      Mixlib::ShellOut.any_instance.stub(:error!)
      Mixlib::ShellOut.any_instance.stub(:stdout).and_return("22756856\t/usr/local\n")
      expect(@job.target_path_disk_usage).to eq(22756856)
    end
  end

  describe "ssh_cmd" do
    it 'should return an ssh command if set by options' do
      @job.recover_opts = { :remote_ssh_cmd => 'ssh postgres@localhost' }
      expect(@job.ssh_cmd).to eq('ssh postgres@localhost')
    end
    
    it 'should return an empty string if ssh command is not set' do
      @job.recover_opts = nil
      expect(@job.ssh_cmd).to eq('')
    end
  end

  describe "target_path_exists?" do
    it 'should return true if path exists' do
      Mixlib::ShellOut.any_instance.stub(:run_command)
      Mixlib::ShellOut.any_instance.stub(:error!)
      Mixlib::ShellOut.any_instance.stub_chain(:status, :exitstatus).and_return(0)
      expect(@job.target_path_exists?).to eq(true)
    end
    it 'should return false if path does not exist' do
      Mixlib::ShellOut.any_instance.stub(:run_command)
      Mixlib::ShellOut.any_instance.stub(:error!)
      Mixlib::ShellOut.any_instance.stub_chain(:status, :exitstatus).and_return(1)
      expect(@job.target_path_exists?).to eq(false)
    end
  end

  describe "create_target_path" do
    it 'should raise RuntimeError if target path could not be created' do
      @job.path = "/home"
      Mixlib::ShellOut.any_instance.stub(:run_command)
      Mixlib::ShellOut.any_instance.stub(:error!)
      Mixlib::ShellOut.any_instance.stub_chain(:status, :exitstatus).and_return(1)
      Mixlib::ShellOut.any_instance.stub(:stderr).and_return("some failure")
      expect{@job.create_target_path}.to raise_error(RuntimeError)
    end

    it 'should not raise RuntimeError if target path could be created' do
      @job.path = "/home"
      Mixlib::ShellOut.any_instance.stub(:run_command)
      Mixlib::ShellOut.any_instance.stub(:error!)
      Mixlib::ShellOut.any_instance.stub_chain(:status, :exitstatus).and_return(0)
      @job.create_target_path
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
end
