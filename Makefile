COMPILER_PATH := lib/apex_parser/apex_compiler.rb
LEXOR_PATH := lib/apex_parser/apex_compiler.l.rb

.PHONY: test
test: $(COMPILER_PATH)
	@time bundle exec rapis

$(COMPILER_PATH): src/apex.racc.rb $(LEXOR_PATH)
	bundle exec racc src/apex.racc.rb -v -o $(COMPILER_PATH)

$(LEXOR_PATH): src/apex.rex.rb
	bundle exec rex src/apex.rex.rb -o $(LEXOR_PATH)

.PHONY: install
install:
	@bundle install --path=vendor/bundle -j4
