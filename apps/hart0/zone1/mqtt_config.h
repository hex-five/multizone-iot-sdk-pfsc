/* Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved */

#ifndef MQTT_CONFIG_H_
#define MQTT_CONFIG_H_


//#define IP_ADDR    "192.168.0.2"
//#define IP_NETMASK "255.255.255.0"
//#define IP_GATEWAY "192.168.0.1"
//#define IP_DNS_1   "8.8.8.8"        /* Google: 8.8.8.8, 8.8.4.4 */
//#define IP_DNS_2   "208.67.222.222" /* OpenDNS: 208.67.222.222, 208.67.220.220  */

#define MQTT_BROKER_FQN     "mqtt-broker.hex-five.com"
#define MQTT_BROKER_PORT    443 /* default 8883 */
//#define MQTT_CLIENT_ID    "mzone-00000000"

#define MQTT_KEEP_ALIVE	600	/* sec */
#define MQTT_QOS		2	/* 0 1 2 */
#define MQTT_RTN 		0	/* 0 = Don't retain */

#define MQTT_WILL_MSG	"offline"
#define MQTT_WILL_TOPIC "/status"  /* "mzone-00000000/status" */
#define MQTT_WILL_QOS	2
#define MQTT_WILL_RTN 	1

#define MQTT_NO_LOCAL   1   /* ignore broker echo - mqtt v1.3.3 */

#define MQTT_REL_TOPIC "hex-five/iot-sdk-pfsc/v2.2.6/+"
#define MQTT_REL_FILES "zone1.bin", "zone2.bin", "zone3.bin", "zone4.bin",
//                     "hart1.bin", "hart2.bin", "hart3.bin", "hart4.bin",


#endif /* MQTT_CONFIG_H_ */
