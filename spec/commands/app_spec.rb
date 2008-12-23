require File.dirname(__FILE__) + '/../base'

module Heroku::Command
	describe App do
		before do
			@cli = prepare_command(App)
		end

		it "shows app info, converting bytes to kbs/mbs" do
			@cli.stub!(:args).and_return(['myapp'])
			@cli.heroku.should_receive(:info).with('myapp').and_return({ :name => 'myapp', :collaborators => [], :code_size => 2*1024, :data_size => 5*1024*1024 })
			@cli.should_receive(:display).with('=== myapp')
			@cli.should_receive(:display).with('Web URL:        http://myapp.heroku.com/')
			@cli.should_receive(:display).with('Code size:      2k')
			@cli.should_receive(:display).with('Data size:      5M')
			@cli.info
		end

		it "shows app info using the --app syntax" do
			@cli.stub!(:args).and_return(['--app', 'myapp'])
			@cli.heroku.should_receive(:info).with('myapp').and_return({ :collaborators => []})
			@cli.info
		end

		it "shows app info reading app from current git dir" do
			@cli.stub!(:args).and_return([])
			@cli.stub!(:extract_app_in_dir).and_return('myapp')
			@cli.heroku.should_receive(:info).with('myapp').and_return({ :collaborators => []})
			@cli.info
		end

		it "creates without a name" do
			@cli.heroku.should_receive(:create).with(nil, {}).and_return("untitled-123")
			@cli.create
		end

		it "creates with a name" do
			@cli.stub!(:args).and_return([ 'myapp' ])
			@cli.heroku.should_receive(:create).with('myapp', {}).and_return("myapp")
			@cli.create
		end

		it "creates adding heroku to git remote" do
			@cli.stub!(:args).and_return([ 'myapp', '--remote' ])
			@cli.heroku.should_receive(:create).and_return('myapp')
			@cli.should_receive(:shell).with('git remote').and_return('')
			@cli.should_receive(:shell).with('git remote add heroku git@heroku.com:myapp.git')
			@cli.create
		end

		it "creates adding a custom git remote" do
			@cli.stub!(:args).and_return([ 'myapp', '--remote', 'myremote' ])
			@cli.heroku.should_receive(:create).and_return('myapp')
			@cli.should_receive(:shell).with('git remote').and_return('')
			@cli.should_receive(:shell).with('git remote add myremote git@heroku.com:myapp.git')
			@cli.create
		end

		it "doesn't add a custom git remote if it already exists" do
			@cli.stub!(:args).and_return([ 'myapp', '--remote', 'myremote' ])
			@cli.heroku.should_receive(:create).and_return('myapp')
			@cli.should_receive(:shell).with('git remote').and_return('myremote')
			@cli.should_not_receive(:shell).with('git remote add myremote git@heroku.com:myapp.git')
			@cli.create
		end

		it "renames an app" do
			@cli.stub!(:args).and_return([ 'myapp2' ])
			@cli.heroku.should_receive(:update).with('myapp', { :name => 'myapp2' })
			@cli.rename
		end

		it "renames updating git remote" do
			@cli.stub!(:args).and_return([ 'myapp2', '--remote' ])
			@cli.heroku.should_receive(:update)
			@cli.should_receive(:shell).with('git remote rm heroku')
			@cli.should_receive(:shell).with('git remote add heroku git@heroku.com:myapp2.git')
			@cli.rename
		end

		it "runs a rake command on the app" do
			@cli.stub!(:args).and_return(([ 'db:migrate' ]))
			@cli.heroku.should_receive(:rake).with('myapp', 'db:migrate')
			@cli.rake
		end

		it "runs a single console command on the app" do
			@cli.stub!(:args).and_return([ '2+2' ])
			@cli.heroku.should_receive(:console).with('myapp', '2+2')
			@cli.console
		end

		it "offers a console, opening and closing the session with the client" do
			@console = mock('heroku console')
			@cli.heroku.should_receive(:console).with('myapp').and_yield(@console)
			Readline.should_receive(:readline).and_return('exit')
			@cli.console
		end

		it "asks to restart servers" do
			@cli.heroku.should_receive(:restart).with('myapp')
			@cli.restart
		end

		it "destroys the app specified with --app if user confirms" do
			@cli.stub!(:ask).and_return('y')
			@cli.stub!(:args).and_return(['--app', 'myapp'])
			@cli.heroku.stub!(:info).and_return({})
			@cli.heroku.should_receive(:destroy).with('myapp')
			@cli.destroy
		end

		it "doesn't destroy the app if the user doesn't confirms" do
			@cli.stub!(:ask).and_return('no')
			@cli.stub!(:args).and_return(['--app', 'myapp'])
			@cli.heroku.stub!(:info).and_return({})
			@cli.heroku.should_not_receive(:destroy)
			@cli.destroy
		end

		it "doesn't destroy the app in the current dir" do
			@cli.stub!(:extract_app).and_return('myapp')
			@cli.heroku.should_not_receive(:destroy)
			@cli.destroy
		end
	end
end