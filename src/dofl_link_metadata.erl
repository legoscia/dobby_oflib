%%%=============================================================================
%%% @copyright (C) 2015, Erlang Solutions Ltd
%%% @author Szymon Mentel <szymon.mentel@erlang-solutions.com>
%%% @doc <Module purpose>
%%% @end
%%%=============================================================================
-module(dofl_link_metadata).
-copyright("2015, Erlang Solutions Ltd.").

%% API
-export([endpoint_with_net_flow/1,
         net_flow_with_flow_mod/2,
         between_flow_mods/2,
         flow_mod_with_flow_table/0]).


-include_lib("dobby_clib/include/dobby.hrl").
-include("dobby_oflib.hrl").

%%%=============================================================================
%%% External functions
%%%=============================================================================

-spec endpoint_with_net_flow(dby_identifier()) -> [tuple()].

endpoint_with_net_flow(Src) ->
    [{type, ep_to_nf}, {src, Src}].


-spec net_flow_with_flow_mod(dby_identifier(), dby_identifier()) -> [tuple()].

net_flow_with_flow_mod(Src, NetFlowId) when Src =:= NetFlowId ->
    of_path_link_metadata(of_path_starts_at, Src, [NetFlowId]);
net_flow_with_flow_mod(Src, NetFlowId) ->
    of_path_link_metadata(of_path_ends_at, Src, [NetFlowId]).


-spec between_flow_mods(dby_identifier(), dby_identifier()) -> [tuple()].

between_flow_mods(Src, NetFlowId) ->
    of_path_link_metadata(of_path_forwards_to, Src, [NetFlowId]).


-spec flow_mod_with_flow_table() -> [tuple()].

flow_mod_with_flow_table() ->
    [{type, of_resource}].

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

of_path_link_metadata(LinkType, Src, NetFlowIds) ->
    [{type, LinkType}, {src, Src}, {net_flow_ids, NetFlowIds}].
