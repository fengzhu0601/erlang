<?php

/**
 * YSDK PHP SDK调用示例代码，基于OpenAPI V3 PHP SDK改造
 *
 */

require_once 'ysdks/Api.php';
require_once 'ysdks/Ysdk.php';
require_once 'ysdks/Payments.php';

// 应用基本信息，需要替换为应用自己的信息，必须和客户端保持一致
// 需要登录腾讯开放平台 open.qq.com，注册开发者，并创建移动应用，审核通过后可以获得APPID和APPKEY
// $appid = '1105335520';
// $appkey = 'muSrUwd5vxMDcUYw';

// // 应用支付基本信息,需要替换为应用自己的信息，必须和客户端保持一致
// // 需要登录腾讯开放平台管理中心 http://op.open.qq.com/，选择已创建的应用进入，然后进入支付结算，完成支付的接入配置
// $pay_appid = 1105335520;


// YSDK后台API的服务器域名
// 调试环境: ysdktest.qq.com
// 正式环境: ysdk.qq.com
// 调试环境仅供调试时调用，调试完成发布至现网环境时请务必修改为正式环境域名
$server_name = 'ysdktest.qq.com';

$appid = "1105335520";
// $appkey = "muSrUwd5vxMDcUYw";
$openkey = $_GET['token'];
$pay_token = $_GET['pay_token'];
$openid = $_GET['openid'];

// $pay_appkey = 'muSrUwd5vxMDcUYw';
$appkey = 'WwTNhxMfmoUGSZe9sBHdOy5kft17A6z1';

$pf = $_GET['pf'];
$pfkey = $_GET['pfkey'];

$amt = 1;
$billno = 11;

$pay_appid = intval($appid);
$pay_appkey = $appkey;



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


$params = array(
    'openid' => $openid,
    'openkey' => $openkey,
    'pay_token' => $pay_token,
    'ts' => $ts,
    'pf' => $pf,
    'pfkey' => $pfkey,
    'zoneid' => $zoneid,
);
$accout_type='qq';
$ret = get_balance_m($sdk,$params,$accout_type);
//print_r("============== get_balance_m ================\n");
//print_r($ret);

echo json_encode($ret, JSON_UNESCAPED_UNICODE);


// Array
// (
//     [ret] => 0
//     [balance] => 5
//     [gen_balance] => 0
//     [first_save] => 0
//     [save_amt] => 5
//     [gen_expire] => 0
//     [tss_list] => Array
//         (
//         )
// )


// end of script
