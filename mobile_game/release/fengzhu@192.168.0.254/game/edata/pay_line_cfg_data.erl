-module(pay_line_cfg_data).

-export([lookup_pay_line_cfg/1]).

lookup_pay_line_cfg(1) -> {1,{pay_line_cfg,1,2,5,8,11,14}};
lookup_pay_line_cfg(2) -> {2,{pay_line_cfg,2,1,4,7,10,13}};
lookup_pay_line_cfg(3) -> {3,{pay_line_cfg,3,3,6,9,12,15}};
lookup_pay_line_cfg(4) -> {4,{pay_line_cfg,4,1,5,9,11,13}};
lookup_pay_line_cfg(5) -> {5,{pay_line_cfg,5,3,5,7,11,15}};
lookup_pay_line_cfg(6) -> {6,{pay_line_cfg,6,1,4,8,10,13}};
lookup_pay_line_cfg(7) -> {7,{pay_line_cfg,7,3,6,8,12,15}};
lookup_pay_line_cfg(8) -> {8,{pay_line_cfg,8,2,4,7,10,14}};
lookup_pay_line_cfg(9) -> {9,{pay_line_cfg,9,2,6,9,12,14}};
lookup_pay_line_cfg(_) -> none.
