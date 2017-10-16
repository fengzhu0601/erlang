<?php

/**
 * YSDK PHP SDK调用示例代码，基于OpenAPI V3 PHP SDK改造
 *
 */

require_once 'ysdks/Api.php';
require_once 'ysdks/Ysdk.php';
require_once 'ysdks/Payments.php';

require_once( './config.php');
require_once( './db.php');
require_once( './payment_op.php');

// YSDK后台API的服务器域名
// 调试环境: ysdktest.qq.com
// 正式环境: ysdk.qq.com
// 调试环境仅供调试时调用，调试完成发布至现网环境时请务必修改为正式环境域名
$server_name = 'ysdktest.qq.com';
// $server_name = 'ysdk.qq.com';

//https://ysdktest.qq.com/mpay/pay_m

// openid:

// appid:1105335520

// appkey:muSrUwd5vxMDcUYw

// token:A9697D475E9AF480B26AF74FA932B1E5

// payToken:DBD2792E905A360C9B9B71FBD2AA44F1

// pf:myapp_m_qq-00000000-android-00000000-ysdk

// pfKey:3da66f3410dc1cce6ed8c0fa75ae8173

$appid = '1105335520';//$_GET['appid'];

$openkey = $_GET['token'];
$pay_token = $_GET['pay_token'];
$openid = $_GET['openid'];

// $appkey = "muSrUwd5vxMDcUYw";
$appkey = 'WwTNhxMfmoUGSZe9sBHdOy5kft17A6z1';

$pf = $_GET['pf'];
$pfkey = $_GET['pfkey'];

//$amt = 1;

$amt = $_GET['amt'];


$billno = intval($_GET['billno']);

$serverid = $_GET['serverid'];

$pay_appid = intval($appid);
$pay_appkey = $appkey;

//支付相关参数
$zoneid=1;

// // 应用基本信息，需要替换为应用自己的信息，必须和客户端保持一致
// // 需要登录腾讯开放平台 open.qq.com，注册开发者，并创建移动应用，审核通过后可以获得APPID和APPKEY
// $appid = '1105335520';
// $appkey = 'muSrUwd5vxMDcUYw';

// // 应用支付基本信息,需要替换为应用自己的信息，必须和客户端保持一致
// // 需要登录腾讯开放平台管理中心 http://op.open.qq.com/，选择已创建的应用进入，然后进入支付结算，完成支付的接入配置
// $pay_appid = 1105335520;
// $pay_appkey = 'muSrUwd5vxMDcUYw';



// // 用户的OpenID，从客户端YSDK登录返回的LoginRet获取
// $openid = '91B7F5507B4C19744682F367291FA4BD';
// // 用户的openkey，从客户端YSDK登录返回的LoginRet获取
// $openkey = '03CF08903FC233F74BDF124525E92827';

// // 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
// $pay_token='92F95C9824A87CD8093BFCF00006F885';
// // 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
// $pf='myapp_m_qq-00000000-android-00000000-ysdk';
// // 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
// $pfkey= 'ce4efe0aa3b8b650286b10f29a167695';
// // 支付分区, 需要先在open.qq.com接入支付结算，并配置了分区
// // 注意是分区ID，默认为1，如果在平台配置了分区需要传入对应的分区ID！
// $zoneId=1;

//

//$wx_openid = 'opWlHuN5MPswXCKIt_rslK3rVzhY';
//$wx_accesstoken = 'OezXcEiiBSKSxW0eoylIeHt0vm7XnDERywoT8nPtKwlPeqSpnNNSptvs4gDKDUF7F9RkD2Mw4RKvDt3iZaaVwWcOUPRGPZz71XtIOLWUvz6ROv-_GELuQcL9PXc4Ngj_f-gXQoL0eFludWU86-lg1w';
//$wx_appid = 'wxfcefed3f366fa606';

/// 当前UNIX时间戳
$ts=time();
// 用户的IP，可选，默认为空
$userip = '';

// 创建YSDK实例
$sdk = new Api($appid, $appkey);
// 设置支付信息
$sdk->setPay($pay_appid, $pay_appkey);
// 设置YSDK调用环境
$sdk->setServerName($server_name);

$account = isset($_GET['account'])?$_GET['account']:"qq";

$params = array();
$accout_type='qq';

if ($account == "wx") {

	$params = array(
	    'openid' => $openid,
	    'openkey' => $openkey,
	//    'pay_token' => $pay_token,
	    'ts' => $ts,
	    'pf' => $pf,
	    'pfkey' => $pfkey,
	    'zoneid' => $zoneid,
	    'amt' => $amt,
	    'billno' => $billno
	);
	$accout_type='wx';
} else {
	$params = array(
	    'openid' => $openid,
	    'openkey' => $openkey,
	    'pay_token' => $pay_token,
	    'ts' => $ts,
	    'pf' => $pf,
	    'pfkey' => $pfkey,
	    'zoneid' => $zoneid,
	    'amt' => $amt,
	    'billno' => $billno
	);
}

$ret = pay_m($sdk, $params, $accout_type);
//print_r("============== pay_m ================\n");
//print_r($ret);

if ($ret[ret] == 0) {
// 	$serverid = '11';
// $openid = 'aaaaaaaaaaaaaaaaa';
// $amt = '10' ;
// $billno = '11111111111' ;
// $result = '0';

   insert_payment($serverid,$openid,$amt,$billno,$ret[ret]);
} 

echo json_encode($ret, JSON_UNESCAPED_UNICODE);

// Array
// (
//     [ret] => 0
//     [billno] => 11
//     [balance] => 4
//     [gen_balance] => 0
//     [used_gen_amt] => 0
// )
// Array
// (
//     [ret] => 1018
//     [err_code] => 1018--2-18
//     [msg] => token校验失败(18)
//     [billno] => 12
// )
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ php qq_pay_m.php 
// Array
// (
//     [ret] => 0
//     [billno] => 12
//     [balance] => 3
//     [gen_balance] => 0
//     [used_gen_amt] => 0
// )
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ php qq_pay_m.php 
// Array
// (
//     [ret] => 1002215
//     [err_code] => 1002-215-0
//     [msg] => 订单已存在，不允许当前操作
//     [billno] => 12
// )
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ 
// ubuntu@VM-201-6-ubuntu:~/www/html$ php qq_pay_m.php 
// Array
// (
//     [ret] => 1004
//     [err_code] => 1034-112-0
//     [msg] => 余额不足
//     [billno] => 13
// )

// end of script
