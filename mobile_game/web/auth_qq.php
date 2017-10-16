<?php

/**
 * YSDK PHP SDK调用示例代码，基于OpenAPI V3 PHP SDK改造
 *
 */

require_once 'ysdks/Api.php';
require_once 'ysdks/Ysdk.php';
require_once 'ysdks/Payments.php';

  header("Cache-Control: no-cache, must-revalidate"); //HTTP 1.1
  header("Pragma: no-cache"); //HTTP 1.0
  // header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past
  header("Content-type: text/html; charset=utf-8");

// YSDK后台API的服务器域名
// 调试环境: ysdktest.qq.com
// 正式环境: ysdk.qq.com
// 调试环境仅供调试时调用，调试完成发布至现网环境时请务必修改为正式环境域名
$server_name = 'ysdktest.qq.com';
// $server_name = 'ysdk.qq.com';

$openid = $_GET['openid'];//"0436D81315D5A58138FC861CEEB51CA8";

$openkey = $_GET['token'];

$appid = $_GET['appid'];

//$appkey = $_GET['appkey'];

// 应用基本信息，需要替换为应用自己的信息，必须和客户端保持一致
// 需要登录腾讯开放平台 open.qq.com，注册开发者，并创建移动应用，审核通过后可以获得APPID和APPKEY

//$appid = '1105335520';
//$appkey = 'muSrUwd5vxMDcUYw';
$appkey = 'WwTNhxMfmoUGSZe9sBHdOy5kft17A6z1';
$account_type = isset($_GET['account'])?$_GET['account']:"qq";

$zoneId=1;

//token ： 03CF08903FC233F74BDF124525E92827
// paytoken：92F95C9824A87CD8093BFCF00006F885
// openid：91B7F5507B4C19744682F367291FA4BD
// pf：myapp_m_qq-00000000-android-00000000-ysdk
// pf_key：ce4efe0aa3b8b650286b10f29a167695

//

/// 当前UNIX时间戳
$ts=time();
// 用户的IP，可选，默认为空
$userip = '';

//支付相关参数
$zoneid=1;

// 创建YSDK实例
$sdk = new Api($appid, $appkey);
// 设置支付信息
$sdk->setPay($pay_appid, $pay_appkey);
// 设置YSDK调用环境
$sdk->setServerName($server_name);

if ($account_type == "wx") {
    $appkey = 'a550c886007709c814af5ffc3d2732f9';
    $wx_openid = $openid;
    $wx_accesstoken = $openkey;
    $wx_appid = $appid;

    $params = array(
        'appid' => $wx_appid,
        'openid' => $wx_openid,
        'userip' => $userip,
        'sig' => md5($appkey.$ts),
        'access_token' => $wx_accesstoken,
        'timestamp' => $ts,
    );

    $ret = wx_check_token($sdk, $params);

    if ($ret[ret] == 0) {
        apc_store($openid, $openkey, 1800);
    } else {
        //apc_delete()
    }
    echo json_encode($ret, JSON_UNESCAPED_UNICODE);
} else {

    $params = array(
      'appid' => $appid,
      'openid' => $openid,
      'openkey' => $openkey,
      'userip' => $userip,
      'sig' =>   md5($appkey.$ts),
      'timestamp' => $ts,
    );

    $ret = qq_check_token($sdk, $params);

    if ($ret[ret] == 0) {
    	apc_store($openid, $openkey, 1800);
    } else {
    	//apc_delete()
    }
    echo json_encode($ret, JSON_UNESCAPED_UNICODE);
}

//$ret[ret] = strval($ret[ret]);

//print_r($ret);



//print $str[0] ."," .  $str[1] ."," .  $str[2];

//echo $str;

//echo json_encode($ret);

//print_r("============== qq_check_token ================\n");
//print_r($ret);

// if ($argc != 2) { 
// echo_help(); 
// } 


// $fun = $argv[1];

// if($fun == 'help'){
//     echo_help();
// }


