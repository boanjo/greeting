%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc Web server for greeting.

-module(greeting_web).
-author("Mochi Media <dev@mochimedia.com>").

-export([start/1, stop/0, loop/2]).

%% External API

start(Options) ->
    {DocRoot, Options1} = get_option(docroot, Options),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end,
    mochiweb_http:start([{name, ?MODULE}, {loop, Loop} | Options1]).

stop() ->
    mochiweb_http:stop(?MODULE).


get_status(Key) ->
    Val = ets:lookup(current_pond_status, Key),
    case Val of
	[{_Key, Ret}] ->
	    Ret;
	_ ->
	    Ret = undefined,
	    Ret
    end.

loop(Req, DocRoot) ->
    "/" ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
		    "status" ->
                        {ok, HTMLOutput} = greeting_dtl:render([{def_feed_amount, "80"}, 
								{temp, get_status(temp)}, 
								{rain, get_status(rain)}, 
								{level, get_status(level)},
								{flow, get_status(flow)},
								{state, get_status(state)},
								{time, get_status(time)}]),
                        Req:respond({200, [{"Content-Type", "text/html"}],
				     HTMLOutput});		    
		    "feed" ->
			serial:send("feed=80"),
			Req:respond({200, [{"Content-Type", "text/plain"}],
				     "Feeding completed!\n"}),
			io:format("Feeding!", []);
                    _ ->
                        Req:serve_file(Path, DocRoot)
		end;
	    'POST' ->
                case Path of
		    "status" ->
                        PostData = Req:parse_post(),
                        FeedAmount = proplists:get_value("feed_amount", PostData, "60"),
			serial:send("feed=" ++ FeedAmount),
			io:format("Feed amount ~p ~n", [FeedAmount]),
			Req:respond({200, [{"Content-Type", "text/plain"}],
				     "Feeding completed!\n"});
			
                    _ ->
                        Req:not_found()
                end;           
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

%% Internal API

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

you_should_write_a_test() ->
    ?assertEqual(
       "No, but I will!",
       "Have you written any tests?"),
    ok.

-endif.
