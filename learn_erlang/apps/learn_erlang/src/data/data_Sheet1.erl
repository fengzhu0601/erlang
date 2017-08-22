-module(data_Sheet1).

-export([get/1]).

get(2) -> [2,two,ii];
get(3) -> [3,three,iii];
get(4) -> [4,four,iv];
get(5) -> [5,five,v];
get(_) -> {0,[{0,0,0}]}.
