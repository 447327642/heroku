require File.expand_path("../base", File.dirname(__FILE__))

module Heroku::Command
  describe Scaling do
    before(:each) do
      @cli = prepare_command(Scaling)
      @cli.stub(:options).and_return(:app => "myapp")
    end

    it "asks to restart servers" do
      @cli.heroku.should_receive(:restart).with('myapp')
      @cli.restart
    end

    it "scales dynos" do
      @cli.stub!(:args).and_return(['+4'])
      @cli.stub!(:options).and_return(:app => "myapp")
      @cli.heroku.should_receive(:set_dynos).with('myapp', '+4').and_return(7)
      @cli.dynos
    end

    it "lists processes" do
      @cli.should_receive(:extract_app).and_return("myapp")
      @cli.heroku.should_receive(:ps).and_return([
        { 'process' => 'ps.1', 'command' => 'rake', 'elapsed' => 3 }
      ])
      @cli.ps
    end
  end
end
