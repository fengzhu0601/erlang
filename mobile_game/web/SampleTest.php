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
$appid = '1105335520';
$appkey = 'muSrUwd5vxMDcUYw';

// 应用支付基本信息,需要替换为应用自己的信息，必须和客户端保持一致
// 需要登录腾讯开放平台管理中心 http://op.open.qq.com/，选择已创建的应用进入，然后进入支付结算，完成支付的接入配置
$pay_appid = 1105335520;
$pay_appkey = 'muSrUwd5vxMDcUYw';

// YSDK后台API的服务器域名
// 调试环境: ysdktest.qq.com
// 正式环境: ysdk.qq.com
// 调试环境仅供调试时调用，调试完成发布至现网环境时请务必修改为正式环境域名
$server_name = 'ysdktest.qq.com';

// 用户的OpenID，从客户端YSDK登录返回的LoginRet获取
$openid = '1B3C4822236840403571E30922A8F088';
// 用户的openkey，从客户端YSDK登录返回的LoginRet获取
$openkey = '9F2806884C8703F7FEA1490B474940F4';

// 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
$pay_token='CC3CB5E77BDA623016CFA3162DA3EFA8';
// 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
$pf='desktop_m_qq-73213123-android-73213123-qq-100703379-0EF80D52AE52324D51958FE6EDC3DBF3';
// 支付接口票据, 从客户端YSDK登录返回的LoginRet获取
$pfkey= '94d7e9a1f441b69f26b113214760100e';
// 支付分区, 需要先在open.qq.com接入支付结算，并配置了分区
// 注意是分区ID，默认为1，如果在平台配置了分区需要传入对应的分区ID！
$zoneId=1;

//

$wx_openid = 'opWlHuN5MPswXCKIt_rslK3rVzhY';
$wx_accesstoken = 'OezXcEiiBSKSxW0eoylIeHt0vm7XnDERywoT8nPtKwlPeqSpnNNSptvs4gDKDUF7F9RkD2Mw4RKvDt3iZaaVwWcOUPRGPZz71XtIOLWUvz6ROv-_GELuQcL9PXc4Ngj_f-gXQoL0eFludWU86-lg1w';
$wx_appid = 'wxfcefed3f366fa606';

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

if ($argc != 2) { 
echo_help(); 
} 


$fun = $argv[1];

if($fun == 'help'){
    echo_help();
}

if($fun == 'qq_check_token'){
    $params = array(
        'appid' => $appid,
        'openid' => $openid,
        'openkey' => $openkey,
        'userip' => $userip,
        'sig' =>   md5($appkey.$ts),
        'timestamp' => $ts,
    );
    $ret = qq_check_token($sdk, $params);
    print_r("============== qq_check_token ================\n");
    print_r($ret);
}

elseif($fun == 'wx_check_token'){
    $params = array(
        'appid' => $wx_appid,
        'openid' => $wx_openid,
        'userip' => $userip,
        'sig' => md5($appkey.$ts),
        'access_token' => $wx_accesstoken,
        'timestamp' => $ts,
    );

    $ret = wx_check_token($sdk, $params);
    print_r("============== wx_check_token ================\n");
    print_r($ret);
}

elseif($fun == 'get_balance_m'){
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
    $ret = get_balance_m($sdk, $params,$accout_type);
    print_r("============== get_balance_m ================\n");
    print_r($ret);
}

elseif($fun == 'pay_m'){
    $amt = 10;
    $params = array(
        'openid' => $openid,
        'openkey' => $openkey,
        'pay_token' => $pay_token,
        'ts' => $ts,
        'pf' => $pf,
        'pfkey' => $pfkey,
        'zoneid' => $zoneid,
        'amt' => $amt,
    );
	$accout_type='qq';
    $ret = pay_m($sdk, $params, $accout_type);
    print_r("============== pay_m ================\n");
    print_r($ret);
}

elseif($fun == 'present_m'){
    $discountid = '';
    $giftid = '';
    $presenttimes = 50;
    $params = array(
        'openid' => $openid,
        'openkey' => $openkey,
        'pay_token' => $pay_token,
        'ts' => $ts,
        'pf' => $pf,
        'pfkey' => $pfkey,
        'zoneid' => $zoneid,
        'discountid' => $discountid,
        'giftid' => $giftid,
        'presenttimes' => $presenttimes
    );
	$accout_type='qq';
    $ret = present_m($sdk, $params, $accout_type);
    print_r("============== present_m ================\n");
    print_r($ret);
}


else{
    print_r("=============fun参数缺失或者输入参数错误==============\n");
    echo_help();
}


function echo_help(){
    print_r("============YSDK PHP SDK测试帮助===============\n");
    print_r("============php SampleTest.php qq_check_token 验证手Q的登录态==================\n");
    print_r("============php SampleTest.php wx_check_token 验证微信的登录态===============\n");
    print_r("============php SampleTest.php get_balance_m  获取用户游戏币余额===============\n");
    print_r("============php SampleTest.php pay_m  		   扣除游戏币接口===============\n");
}

// end of script
