%%%-------------------------------------------------------------------
%% @doc vonnegut public API
%% @end
%%%-------------------------------------------------------------------

-module(vonnegut_app).

-behaviour(application).

%% Application callbacks
-export([start/2,
         stop/1,
         swap_lager/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    init_tables(),
    vonnegut_sup:start_link().


%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

init_tables() ->
    vg_log_segments:init_table(),
    vg_topics:init_table().

%% TODO: ifdef this out in non-test builds
swap_lager(Pid) ->
    %% our testing environment has provided us with a remote
    %% lager sink to target messages at, but we can't target
    %% it directly, so proxy message through to it.
    Proxy = spawn(fun Loop() ->
                          receive
                              E -> Pid ! E
                          end,
                          Loop()
                  end),
    Lager = whereis(lager_event),
    true = unregister(lager_event),
    case (catch register(lager_event, Proxy)) of
        true ->
            lager:info("swapped local lager_event server with: ~p", [Pid]);
        Other ->
            register(lager_event, Lager),
            lager:info("noes we failed: ~p", [Other])
    end.
