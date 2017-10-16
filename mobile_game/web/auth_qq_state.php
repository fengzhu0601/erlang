<?php

  header("Cache-Control: no-cache, must-revalidate"); //HTTP 1.1
  header("Pragma: no-cache"); //HTTP 1.0
  header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past

$openid = $_GET['openid'];//"0436D81315D5A58138FC861CEEB51CA8";

$my_token = $_GET['token'];

$token =  apc_fetch($openid);

//echo $openid .'<br/>' . $my_token .'<br/>' . $token .'<br/>';

if ($my_token == $token && $my_token != "") {
	echo "ok";
} else {
	echo "error";
}

//echo $openid . "&&" . $token;

?>