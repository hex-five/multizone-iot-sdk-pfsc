/* Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved */

#ifndef MQTT_CONFIG_H_
#define MQTT_CONFIG_H_


//#define IP_ADDR    "192.168.0.2"
//#define IP_NETMASK "255.255.255.0"
//#define IP_GATEWAY "192.168.0.1"
//#define IP_DNS_1   "8.8.8.8"
//#define IP_DNS_2   "8.8.4.4"

#define MQTT_BROKER_FQN	"mqtt-broker.hex-five.com"
/* #define MQTT_BROKER_PORT 443 */
/* #define MQTT_CLIENT_ID	"mzone-00000000" */

#define MQTT_KEEP_ALIVE	600	/* sec */
#define MQTT_QOS		2	/* 0 1 2 */
#define MQTT_RTN 		0	/* 0 = Don't retain */

#define MQTT_WILL_MSG	"offline"
#define MQTT_WILL_TOPIC ""  /* "/status" */
#define MQTT_WILL_QOS	2
#define MQTT_WILL_RTN 	1


#endif /* MQTT_CONFIG_H_ */
