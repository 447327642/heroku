require File.expand_path("../base", File.dirname(__FILE__))

module Heroku::Command
  describe Pg do
    before do
      @pg = prepare_command(Pg)
      @pg.stub!(:config_vars).and_return({
        "DATABASE_URL" => "postgres://database_url",
        "SHARED_DATABASE_URL" => "postgres://other_database_url",
        "HEROKU_POSTGRESQL_RONIN_URL" => "postgres://database_url"
      })
      @pg.stub!(:args).and_return(["--db", "DATABASE_URL"])
      @pg.heroku.stub!(:info).and_return({})
    end

    it "resets the app's database if user confirms" do
      @pg.stub!(:confirm_command).and_return(true)

      fake_client = mock("heroku_postgresql_client")
      fake_client.should_receive("reset")

      @pg.should_receive(:heroku_postgresql_client).with("postgres://database_url").and_return(fake_client)

      @pg.reset
    end

    it "doesn't reset the app's database if the user doesn't confirm" do
      @pg.stub!(:confirm_command).and_return(false)
      @pg.should_not_receive(:heroku_postgresql_client)
      @pg.reset
    end

    context "promotion" do
      it "promotes the specified database" do
        @pg.stub!(:args).and_return(['--db', 'SHARED_DATABASE_URL'])
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_receive(:add_config_vars).with("myapp", {"DATABASE_URL" => @pg.config_vars["SHARED_DATABASE_URL"]})

        @pg.promote
      end

      it "fails if no database is specified" do
        @pg.stub(:args).and_return([])
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)

        lambda { @pg.promote }.should raise_error SystemExit
      end

      it "does not repromote the current DATABASE_URL" do
        @pg.stub(:args).and_return(['--db', 'HEROKU_POSTGRESQL_RONIN_URL'])
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)

        lambda { @pg.promote }.should raise_error SystemExit
      end

      it "does not promote DATABASE_URL" do
        @pg.stub(:args).and_return(['--db', 'DATABASE_URL'])
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)

        lambda { @pg.promote }.should raise_error SystemExit
      end
    end

    context "resolve_db_id" do
      it "defaults to the current DATABASE_URL" do
        pending
        @pg.resolve_db_id(nil, :default => "DATABASE_URL").should == ["CLONED_DATABASE_URL", "postgres://database_url", true]
      end

      it "should use your specified database URL" do
        pending
        @pg.resolve_db_id("OTHER_DATABASE_URL", :default => "DATABASE_URL").should == ["OTHER_DATABASE_URL", "postgres://other_database_url", false]
      end

      it "should fail if there's no default or URL provided" do
        lambda { @pg.resolve_db_id(nil) }.should raise_error SystemExit
      end

      it "should fail if there's no default or URL provided" do
        lambda { @pg.resolve_db_id(nil) }.should raise_error SystemExit
      end
    end
  end
end
