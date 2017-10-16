-module(xml_parse).
-export([
        get_process_list/1
    ]).

-include_lib("xmerl/include/xmerl.hrl").
-include("inc.hrl").

get_process_list(FileName) ->
    {XmlElement, []} = xmerl_scan:file(FileName, [{encoding, 'utf-8'}]),
    case erlang:is_record(XmlElement, xmlElement) of
        true ->
            % Name = XmlElement#xmlElement.name,
            AllContent = XmlElement#xmlElement.content,
            parse_content_xmlelement(AllContent, []);
        W ->
            ?ERROR_LOG("scan xml file error:~p", [W])
    end.

parse_content_xmlelement([], Ret) -> Ret;
parse_content_xmlelement([Record | Tail], Ret) when is_record(Record, xmlElement) ->
    case Record#xmlElement.name of
        'State' ->
            State = parse_state(Record),
            parse_content_xmlelement(Tail, Ret ++ [State]);
        'Event' ->
            Event = parse_event(Record),
            parse_content_xmlelement(Tail, Ret ++ [Event]);
        W ->
            ?ERROR_LOG("parse_content_xmlelement error, find other element:~p", [W]),
            parse_content_xmlelement(Tail, Ret)
    end;
parse_content_xmlelement([_Record | Tail], Ret) ->
    parse_content_xmlelement(Tail, Ret).

parse_state(Record) ->
    Attributes = Record#xmlElement.attributes,
    Content = Record#xmlElement.content,
    {Id} = parse_attribute(Attributes, []),
    AllEvent = parse_content_xmlelement(Content, []),
    {Id, AllEvent}.

parse_event(Record) ->
    Attributes = Record#xmlElement.attributes,
    Content = Record#xmlElement.content,
    {Id, Times} = parse_attribute(Attributes, []),
    {Funcs1, Funcs2} = parse_all_funcs(Content, [], []),
    {Id, Times, Funcs1, Funcs2}.

parse_attribute([], Ret) -> list_to_tuple(Ret);
parse_attribute([Attribute | Tail], Ret) ->
    case Attribute#xmlAttribute.name =/= 'Desc' of
        true ->
            NewRet = Ret ++ [list_to_integer(Attribute#xmlAttribute.value)],
            parse_attribute(Tail, NewRet);
        _ ->
            parse_attribute(Tail, Ret)
    end.

parse_all_funcs([], Ret1, Ret2) -> {Ret1, Ret2};
parse_all_funcs([Record | Tail], Ret1, Ret2) when is_record(Record, xmlElement) ->
    case Record#xmlElement.name of
        'Can' ->
            EventAttributes = Record#xmlElement.attributes,
            FuncTuple = parse_func(EventAttributes, {}),    %% {Func, Par}
            parse_all_funcs(Tail, Ret1 ++ [FuncTuple], Ret2);
        'Do' ->
            EventAttributes = Record#xmlElement.attributes,
            FuncTuple = parse_func(EventAttributes, {}),    %% {Func, Par}
            parse_all_funcs(Tail, Ret1, Ret2 ++ [FuncTuple]);
        W ->
            ?ERROR_LOG("parse_all_funcs error, find other element:~p", [W]),
            parse_all_funcs(Tail, Ret1, Ret2)
    end;
parse_all_funcs([_Record | Tail], Ret1, Ret2) ->
    parse_all_funcs(Tail, Ret1, Ret2).

parse_func([], Ret) -> Ret;
parse_func([Attributes | Tail], Ret) ->
    case is_record(Attributes, xmlAttribute) of
        true ->
            NewRet = case Attributes#xmlAttribute.name of
                'Func' ->
                    tuple_to_list(Ret) ++ [list_to_atom(Attributes#xmlAttribute.value)];
                'Par' ->
                    case Attributes#xmlAttribute.value of
                        [] ->
                            tuple_to_list(Ret) ++ [""];
                        _ ->
                            {ok, Par} = string_to_term(Attributes#xmlAttribute.value),
                            tuple_to_list(Ret) ++ [Par]
                    end;
                _ ->
                    tuple_to_list(Ret)
            end,
            parse_func(Tail, list_to_tuple(NewRet));
        _ ->
            parse_func(Tail, Ret)
    end.

string_to_term(String) ->
    case erl_scan:string(String ++ ".") of
        {ok, Tokens, _} ->
            erl_parse:parse_term(Tokens);
        {error, Err, _} -> 
            ?ERROR_LOG("string_to_term error:~p~p", [String, Err]),
            {error, Err};
        Err ->
            ?ERROR_LOG("string_to_term error:~p~p", [String, Err]),
            {error, Err}
    end.
