%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%% 载入房间设计图
%%% @end
%%% Created : 05. 四月 2016 下午4:45
%%%-------------------------------------------------------------------
-module(load_rule_chart).
-author("clark").

%% API
-export
([
    get_scene_states/1,
    get_ai_states/1
]).



-include_lib("xmerl/include/xmerl.hrl").
-include("inc.hrl").
-include("load_rule_chart.hrl").


-define(chart_item_count, '@chart_item_count@').

%% 10011 scene_
get_scene_states(CfgID) ->
    XmlFile = "./data/scene/scene_"  ++ integer_to_list(CfgID) ++ ".xml",
    get_states(XmlFile).

get_ai_states(CfgID) when is_integer(CfgID) ->
    XmlFile =  "./data/ai/ai_" ++ integer_to_list(CfgID) ++ ".xml",
    get_states(XmlFile);

get_ai_states(CfgAtom) when is_atom(CfgAtom) ->
    XmlFile =  "./data/ai/ai_" ++ atom_to_list(CfgAtom) ++ ".xml",
    get_states(XmlFile).

%% 获得建筑图
get_states(FileName) ->
    % ?INFO_LOG("get_states ~p", [FileName]),
    {XmlElement, []} = xmerl_scan:file(FileName, [{encoding, 'utf-8'}]),
    case erlang:is_record(XmlElement, xmlElement) of
        true ->
            util:set_pd_field(?chart_item_count, 0),
            AllContent = XmlElement#xmlElement.content,
            parse_context(AllContent);

        W ->
            ?ERROR_LOG("scan xml file error:~p", [W])
    end.


%% 解析结构体
parse_context([]) -> [];
parse_context([Record | Tail]) ->
    case parse_item( get_item_type(Record), Record) of
        nil -> parse_context(Tail);
        Item -> [Item] ++ parse_context(Tail)
    end.



%% state数据项
get_item_type(Record) when is_record(Record, xmlElement) -> Record#xmlElement.name;
get_item_type(_Record) -> nil.


%% state数据项
parse_item('State', Record) ->
    Attributes = Record#xmlElement.attributes,
    Content = Record#xmlElement.content,
    ItemKey = util:get_pd_field(?chart_item_count, 0) + 1,
    util:set_pd_field(?chart_item_count, ItemKey),
    #rule_porsche_state
    {
        key         = ItemKey,
        state_id    = find_attributes(integer, 'StateId', Attributes),
        evt_list    = parse_context(Content)
    };


%% Event数据项
parse_item('Event', Record) ->
    Attributes = Record#xmlElement.attributes,
    Content = Record#xmlElement.content,
    ItemKey = util:get_pd_field(?chart_item_count, 0) + 1,
    util:set_pd_field(?chart_item_count, ItemKey),
    CanDoList = parse_context(Content),
    IsCan =
        fun(Item) ->
            case Item of
                #rule_porsche_can{} -> true;
                _ -> false
            end
        end,
    IsTrueDo =
        fun(Item) ->
            case Item of
                #rule_porsche_do{type=true} -> true;
                _ -> false
            end
        end,
    IsFalseDo =
        fun(Item) ->
            case Item of
                #rule_porsche_do{type=false} -> true;
                _ -> false
            end
        end,
    #rule_porsche_event
    {
        key         = ItemKey,
        evt_id      = find_attributes(integer, 'EventId', Attributes),
        times       = find_attributes(integer, 'Times', Attributes),
        can         = lists:filter(IsCan, CanDoList),
        true        = lists:filter(IsTrueDo, CanDoList),
        false       = lists:filter(IsFalseDo, CanDoList)
    };


%% Can数据项
parse_item('Can', Record) ->
    ItemKey = util:get_pd_field(?chart_item_count, 0) + 1,
    util:set_pd_field(?chart_item_count, ItemKey),
    Attributes = Record#xmlElement.attributes,
    #rule_porsche_can
    {
        key         = ItemKey,
        func        = find_attributes(atom, 'Func', Attributes),
        par         = find_attributes(term, 'Par', Attributes)
    };


%% Do数据项
parse_item('True', Record) ->
    ItemKey = util:get_pd_field(?chart_item_count, 0) + 1,
    util:set_pd_field(?chart_item_count, ItemKey),
    Attributes = Record#xmlElement.attributes,
    #rule_porsche_do
    {
        type        = true,
        key         = ItemKey,
        func        = find_attributes(atom, 'Func', Attributes),
        par         = find_attributes(term, 'Par', Attributes)
    };

parse_item('False', Record) ->
    ItemKey = util:get_pd_field(?chart_item_count, 0) + 1,
    util:set_pd_field(?chart_item_count, ItemKey),
    Attributes = Record#xmlElement.attributes,
    #rule_porsche_do
    {
        type        = false,
        key         = ItemKey,
        func        = find_attributes(atom, 'Func', Attributes),
        par         = find_attributes(term, 'Par', Attributes)
    };

%% 未定义
parse_item(_, _Record) ->
    nil.


%% 查找属性值
find_attributes(_Type, _Key, []) -> nil;
find_attributes(Type, Key, [Attribute | Tail]) ->
    case Attribute#xmlAttribute.name =:= Key of
        true ->
            case Type of
                integer ->
                    list_to_integer(Attribute#xmlAttribute.value);

                atom ->
                    list_to_atom(Attribute#xmlAttribute.value);

                term ->
                    case string_to_term(Attribute#xmlAttribute.value) of
                        {ok, Par} -> [Par];
                        _ -> nil
                    end;

                _ ->
                    nil
            end;

        _ ->
            find_attributes(Type, Key, Tail)
    end.


string_to_term(String) ->
    case erl_scan:string(String ++ ".") of
        {ok, Tokens, _} ->
            Ret = erl_parse:parse_term(Tokens),
            Ret;

        {error, Err, _} ->
            ?ERROR_LOG("string_to_term error:~p~p", [String, Err]),
            {error, Err};

        Err ->
            ?ERROR_LOG("string_to_term error:~p~p", [String, Err]),
            {error, Err}
    end.

