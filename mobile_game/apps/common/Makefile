REBAR = ../../rebar
DIALYZER = dialyzer

DIALYZER_WARNINGS = -Werror_handling \
                    -Wrace_conditions -Wunderspecs 

.PHONY: all compile test qc clean dialyze deps sync gmsg

all: compile

compile:
	@$(REBAR) compile

test: compile
	@$(REBAR) eunit skip_deps=true

clean:
	@$(REBAR) clean

dialyze: 
	@$(DIALYZER)  --src src -r ebin  -pa ebin -I src --fullpath  $(DIALYZER_WARNINGS) 
