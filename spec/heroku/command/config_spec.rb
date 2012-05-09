require "spec_helper"
require "heroku/command/config"

module Heroku::Command
  describe Config do
    before(:each) do
      stub_core
      api.post_app("name" => "myapp", "stack" => "cedar")
    end

    after(:each) do
      api.delete_app("myapp")
    end

    it "shows all configs" do
      api.put_config_vars("myapp", { 'A' => 'one', 'B' => 'two' })
      stderr, stdout = execute("config")
      stderr.should == ""
      stdout.should == <<-STDOUT
=== Config Vars for myapp
A: one
B: two
STDOUT
    end

    it "does not trim long values" do
      api.put_config_vars("myapp", { 'LONG' => 'A' * 60 })
      stderr, stdout = execute("config")
      stderr.should == ""
      stdout.should == <<-STDOUT
=== Config Vars for myapp
LONG: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
STDOUT
    end

    it "shows configs in a shell compatible format" do
      api.put_config_vars("myapp", { 'A' => 'one', 'B' => 'two' })
      stderr, stdout = execute("config --shell")
      stderr.should == ""
      stdout.should == <<-STDOUT
A=one
B=two
STDOUT
    end

    context("add") do

      it "sets config vars" do
        stderr, stdout = execute("config:add a=1 b=2")
        stderr.should == ""
        stdout.should == <<-STDOUT
Adding config vars and restarting myapp... done, v2
A: 1
B: 2
      STDOUT
      end

      it "allows config vars with = in the value" do
        stderr, stdout = execute("config:add a=b=c")
        stderr.should == ""
        stdout.should == <<-STDOUT
Adding config vars and restarting myapp... done, v2
A: b=c
STDOUT
      end

    end

    describe "config:remove" do

      it "exits with a help notice when no keys are provides" do
        lambda { execute("config:remove") }.should raise_error(CommandFailed, "Usage: heroku config:remove KEY1 [KEY2 ...]")
      end

      context "when one key is provided" do

        it "removes a single key" do
          stderr, stdout = execute("config:remove a")
          stderr.should == ""
          stdout.should == <<-STDOUT
Removing a and restarting myapp... done, v2
STDOUT
        end
      end

      context "when more than one key is provided" do
        let(:args) { ['a', 'b'] }

        it "removes all given keys" do
          stderr, stdout = execute("config:remove a b")
          stderr.should == ""
          stdout.should == <<-STDOUT
Removing a and restarting myapp... done, v2
Removing b and restarting myapp... done, v2
STDOUT
        end
      end
    end
  end
end
