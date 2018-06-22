.PHONY: test
test: lib/apex.rb
	@time bundle exec ruby ./lib/run.rb

lib/apex.rb: lib/apex.racc.rb lib/apex.l.rb
	bundle exec racc ./lib/apex.racc.rb -v -o ./lib/apex.rb

lib/apex.l.rb: lib/apex.rex.rb
	bundle exec rex ./lib/apex.rex.rb -o ./lib/apex.l.rb

.PHONY: install
install:
	@bundle install --path=vendor/bundle -j4
