/* Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved */

#ifndef OWI_SEQUENCE_H_
#define OWI_SEQUENCE_H_

#include <stdint.h>

typedef enum{
	MAIN,
	FOLD,
	UNFOLD,
} owi_sequence;

void owi_sequence_start(owi_sequence);
void owi_sequence_stop(void);
void owi_sequence_stop_req(void);
int owi_sequence_next(void);

int32_t owi_sequence_get_cmd(void);
int owi_sequence_get_ms(void);

int owi_sequence_is_running(void);

#endif
