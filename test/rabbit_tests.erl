-module(rabbit_tests).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

run_test_() ->
    {setup, fun setup/0, fun cleanup/1,
        [
            {"connection tests", [
                    {"concurent channel", fun t1/0}
                ]}
        ]
    }.

setup() ->
    net_kernel:start(['test@127.0.0.1', longnames]),
    application:set_env(usagi, rabbits, [
            {rabbit1, [
                    {type, network},
                    {host,"192.168.33.10"},
                    {port, 5672},
                    {username, <<"admin">>},
                    {password, <<"admin">>}
                ]}
        ]),
    application:set_env(amqp_client, prefer_ipv6, false),
    ok = usagi:start().

cleanup(_) ->
    usagi:stop().

%% ===================================================================
%% Test cases
%% ===================================================================

t1() ->
    Name = channel_1,
    P1 = proc_lib:spawn(?MODULE, t1_w, [self(), Name]),
    P2 = proc_lib:spawn(?MODULE, t1_w, [self(), Name]),
    P3 = proc_lib:spawn(?MODULE, t1_w, [self(), Name]),
    P4 = proc_lib:spawn(?MODULE, t1_w, [self(), Name]),
    P5 = proc_lib:spawn(?MODULE, t1_w, [self(), Name]),
    P1R = get_result(P1),
    P2R = get_result(P2),
    P3R = get_result(P3),
    P4R = get_result(P4),
    P5R = get_result(P5),
    ?assertMatch(P1R, P2R),
    ?assertMatch(P1R, P3R),
    ?assertMatch(P1R, P4R),
    ?assertMatch(P1R, P5R).


%% ===================================================================
%% Helpers
%% ===================================================================

t1_w(Parent, Name) ->
    Channel = usagi_agent:get_channel(Name),
    receive
        get ->
            Parent ! {self(), Channel}
    end.

get_result(Pid) ->
    Pid ! get,
    receive
        {Pid, Res} ->
            Res
    end.