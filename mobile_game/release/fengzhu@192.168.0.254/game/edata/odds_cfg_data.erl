-module(odds_cfg_data).

-export([lookup_odds_cfg/1]).

lookup_odds_cfg(1) -> {1,{odds_cfg,1,0,0,3,10,50}};
lookup_odds_cfg(2) -> {2,{odds_cfg,2,0,0,3,10,50}};
lookup_odds_cfg(3) -> {3,{odds_cfg,3,0,0,5,25,200}};
lookup_odds_cfg(4) -> {4,{odds_cfg,4,0,0,5,25,200}};
lookup_odds_cfg(5) -> {5,{odds_cfg,5,0,2,10,50,300}};
lookup_odds_cfg(6) -> {6,{odds_cfg,6,0,2,10,50,300}};
lookup_odds_cfg(7) -> {7,{odds_cfg,7,0,5,20,150,1000}};
lookup_odds_cfg(8) -> {8,{odds_cfg,8,0,5,20,150,1000}};
lookup_odds_cfg(9) -> {9,{odds_cfg,9,0,5,25,250,5000}};
lookup_odds_cfg(10) -> {10,{odds_cfg,10,2,10,50,500,10000}};
lookup_odds_cfg(11) -> {11,{odds_cfg,11,0,1,5,10,100}};
lookup_odds_cfg(12) -> {12,{odds_cfg,12,0,0,0,0,0}};
lookup_odds_cfg(_) -> none.
