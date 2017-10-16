<?php


function current_time( $type, $gmt = 0 ) {
	        switch ( $type ) {
	                case 'mysql':
	                        return ( $gmt ) ? gmdate( 'Y-m-d H:i:s' ) : gmdate( 'Y-m-d H:i:s', ( time() + ( 8 * HOUR_IN_SECONDS ) ) );
	                case 'timestamp':
	                        return ( $gmt ) ? time() : time() + ( 8 * HOUR_IN_SECONDS );
	                default:
	                        return ( $gmt ) ? date( $type ) : date( $type, time() + ( 8 * HOUR_IN_SECONDS ) );
	        }
	}

function insert_payment($serverid, $openid, $amt, $billno,$result) {
	global $db;
	$db->hide_errors();
	$cur_date = current_time('timestamp');
	$result = $db->query("insert into payment_tab (pid,serverid,openid,time,amt,billno,result) VALUES (NULL,$serverid, '$openid', '$cur_date',$amt, '$billno','$result')");

	if ($result) {
		$id = (int) $db->insert_id;
		return $id;
        } else {
		return false;
	}

}


// test

?>