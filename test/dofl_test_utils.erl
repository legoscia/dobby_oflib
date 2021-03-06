%%%=============================================================================
%%% @copyright (C) 2015, Erlang Solutions Ltd
%%% @author Szymon Mentel <szymon.mentel@erlang-solutions.com>
%%% @doc Test utilies
%%% @end
%%%=============================================================================
-module(dofl_test_utils).
-copyright("2015, Erlang Solutions Ltd.").

%% API
-export([figure4/0,
         flow_path/0,
         flow_path_to_identifiers/1,
         flow_mod/0,
         flow_mod/1,
         flow_mod_to_table_no/1]).

-include_lib("eunit/include/eunit.hrl").

%%%=============================================================================
%%% External functions
%%%=============================================================================

%% @doc
%% Represents graph from figure 4 in
%% https://docs.google.com/a/erlang-solutions.com/document/d/1HmdKtNvAR1f8JQeyY13kzGMUjdAgPDE9tuszo2OFXwM/edit#heading=h.ofp54z1pu56t
figure4() ->
    Graph = create_graph(),
    [OFP1, OFP2] =
        [begin
             Ep = add_identifier({N, endpoint}, Graph),
             Ofp1 = add_identifier({{N, 1}, of_port}, Graph),
             OfsMetadata = #{datapath_id => no_to_dpid(N), ip => ip(N)},
             Ofs = add_identifier({N, of_switch, OfsMetadata}, Graph),
             Ofp2 = add_identifier({{N, 2}, of_port}, Graph),
             add_link({Ep, Ofp1, connected_to}, Graph),
             add_link({Ofp1, Ofs, port_of}, Graph),
             add_link({Ofp2, Ofs, port_of}, Graph),
             Ofp2
         end || N <- [1,2]],
    add_link({OFP1, OFP2, connected_to}, Graph),
    Graph.

%% @doc
%% Returns sample flow path that can be passed to
%% `dobby_oflib:publish_net_flow/3)'.
flow_path() ->
    [{<<"00:00:00:00:00:01:00:01">>,
      {_OFVersion = 4,
       [{[{in_port,1}],
         [{apply_actions,[{output,2,no_buffer}]}],
         [{table_id,0}, {priority, 100},
          {idle_timeout, 0}, {idle_timeout, 0},
          {cookie, <<0,0,0,0,0,0,0,101>>},
          {cookie_mask, <<0,0,0,0,0,0,0,0>>}]}]
      }},
     {<<"00:00:00:00:00:01:00:02">>,
      {_OFVersion = 4,
       [{[{in_port,2}],
         [{apply_actions,[{output,1,no_buffer}]}],
         [{table_id,0}, {priority, 100},
          {idle_timeout, 0}, {idle_timeout, 0},
          {cookie, <<0,0,0,0,0,0,0,102>>},
          {cookie_mask, <<0,0,0,0,0,0,0,0>>}]}]}
     }].

flow_mod() ->
    {[{in_port,2}],
     [{apply_actions,[{output,1,no_buffer}]}],
     [{table_id, 0}, {priority, 100},
      {idle_timeout, 0}, {idle_timeout, 0},
      {cookie, <<0,0,0,0,0,0,0,102>>},
      {cookie_mask, <<0,0,0,0,0,0,0,0>>}]}.

flow_mod(Cookie) ->
    {[{in_port,2}],
     [{apply_actions,[{output,1,no_buffer}]}],
     [{table_id, 0}, {priority, 100},
      {idle_timeout, 0}, {idle_timeout, 0},
      {cookie, Cookie},
      {cookie_mask, <<0,0,0,0,0,0,0,0>>}]}.

flow_mod_to_table_no({_Matches, _Actions, Opts}) ->
    proplists:get_value(table_id, Opts).

%% @doc
%% Transletes `FlowPath' as returned by ?MODULE:figure4() into a list
%% of subsequent identifiers.
flow_path_to_identifiers(FlowPath) ->
    Fun = fun({_Dpid, {_OFVersion, FlowMods}}) ->
                  [proplists:get_value(cookie, O) || {_M, _I, O} <-FlowMods]
          end,
    lists:map(Fun, FlowPath).


%%%=============================================================================
%%% Internal functions
%%%=============================================================================

create_graph() ->
    digraph:new().

add_identifier({N, Type}, Graph) ->
    digraph:add_vertex(Graph, id(N, Type), #{type => Type});
add_identifier({N, Type, Metadata}, Graph) ->
    digraph:add_vertex(Graph, id(N, Type),
                       maps:put(type, Type, Metadata)).

add_link({Id1, Id2, Type}, Graph) ->
    digraph:add_edge(Graph, Id1, Id2, #{type => Type}),
    digraph:add_edge(Graph, Id2, Id1, #{type => Type});
add_link({Id1, Id2, Type, Metadata}, Graph) ->
    digraph:add_edge(Graph, Id1, Id2, maps:put(type, Type, Metadata)),
    digraph:add_edge(Graph, Id2, Id1, maps:put(type, Type, Metadata)).

id(N, endpoint) ->
    list_to_binary("EP" ++ integer_to_list(N));
id({Sw, N}, of_port) ->
    list_to_binary("OFS"++ integer_to_list(Sw) ++ "/OFP" ++ integer_to_list(N));
id(N, of_switch) ->
    list_to_binary("OFS" ++ integer_to_list(N)).

no_to_dpid(N) ->
    list_to_binary("00:00:00:00:00:01:00:0" ++ integer_to_list(N)).

ip(N) ->
    {10, 0, 0, N}.

path(<<"EP1">>, <<"EP2">>) ->
    [<<"EP1">>,<<"OFS1/OFP1">>,<<"OFS1">>,
     <<"OFS1/OFP2">>,<<"OFS2/OFP2">>,
     <<"OFS2">>,<<"OFS2/OFP1">>,<<"EP2">>];
path(A = <<"EP2">>, B = <<"EP1">>) ->
    lists:reverse(path(B,A)).


%%%=============================================================================
%%% Tests
%%%=============================================================================

figure4_graph_test() ->
    %% GIVEN
    [EP1, EP2] = [id(N, endpoint) || N <- [1,2]],

    %% WHEN
    Graph = figure4(),

    %% THEN
    ?assertEqual(path(EP1, EP2), digraph:get_path(Graph, EP1, EP2)),
    ?assertEqual(path(EP2, EP1), digraph:get_path(Graph, EP2, EP1)).
