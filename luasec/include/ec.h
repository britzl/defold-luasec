/*--------------------------------------------------------------------------
 * LuaSec 1.3.2
 *
 * Copyright (C) 2006-2023 Bruno Silvestre
 *
 *--------------------------------------------------------------------------*/

#ifndef LSEC_EC_H
#define LSEC_EC_H

#include <dmsdk/sdk.h>

#include "compat.h"

#ifndef OPENSSL_NO_EC
#include <openssl/ec.h>

//////// DEFOLD BEGIN
int lsec_find_ec_nid(lua_State *L, const char *str);
#ifndef LSEC_API_OPENSSL_3_0
EC_KEY *lsec_find_ec_key(lua_State *L, const char *str);
#endif
//////// DEFOLD END
#endif

void lsec_get_curves(lua_State *L);
void lsec_load_curves(lua_State *L);

#endif
