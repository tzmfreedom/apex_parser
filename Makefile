lib/apex.rb: lib/apex.racc.rb lib/apex.l.rb
	bundle exec racc ./lib/apex.racc.rb -o ./lib/apex.rb

lib/apex.l.rb: lib/apex.rex.rb
	bundle exec rex ./lib/apex.rex.rb -o ./lib/apex.l.rb

test:
	@bundle exec ruby ./lib/apex.rb < ./lib/sample.apex
