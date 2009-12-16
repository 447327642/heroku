require File.dirname(__FILE__) + '/../base'

module Heroku::Command
	describe Ps do
		before do
			@cli = prepare_command(Ps)
		end

		it "lists processes" do
			@cli.heroku.should_receive(:ps).and_return([
				{ 'command' => 'rake', 'transitioned_at' => Time.now.to_s }
			])
			@cli.index
		end
	end
end
