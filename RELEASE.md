Heroku CLI Release Process
==========================

* Ensure CI is passing `bundle exec rake ci`
* Update version number in `/lib/heroku/version.rb` to X.Y.Z
* Run `bundle install` to update the version of heroku in the Gemfile.lock
* Update changelog.txt
* Stage the changes `git add .`
* Commit the changes `git commit -m "vX.Y.Z"`
* Push the `git push origin master`
* Ensure CI still passes `bundle exec rake ci`
* Release the gem `bundle exec rake gem:release`
* Move to a checkout of the toolbelt repo and make sure everything is up to date `git pull`
* Move to the components/heroku directory, `git fetch` and `git reset --hard HASH` where HASH is commit hash of vX.Y.Z
* Stage `git add .`, commit `git commit -m "bump heroku submodule to vX.Y.Z"`, and push `git push` submodule changes
* Ask in #dx for toolbelt releases
* Create a [new changelog](http://devcenter.heroku.com/admin/changelog_items/new)
* Set the title to `Heroku CLI vX.Y.Z released with #{highlights}`
* Set the description to:
    

        A new version of the Heroku CLI is available with #{details}.

        See the [CLI changelog](https://github.com/heroku/heroku/blob/master/CHANGELOG) for details and update by using `heroku update`.
