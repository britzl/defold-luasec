/*--------------------------------------------------------------------------
 * LuaSec 1.3.2
 *
 * Copyright (C) 2006-2023 Bruno Silvestre
 *
 *--------------------------------------------------------------------------*/

#ifndef LSEC_COMPAT_H
#define LSEC_COMPAT_H

#include <openssl/ssl.h>

//------------------------------------------------------------------------------

#if defined(_WIN32)
#define LSEC_API __declspec(dllexport) 
#else
#define LSEC_API extern
#endif

//////// DEFOLD BEGIN
#define LUASOCKET_DEBUG
#define WITH_LUASOCKET

// Extension lib defines
#define LIB_NAME "LuaSec"
#define MODULE_NAME "luasec"
//////// DEFOLD END
//------------------------------------------------------------------------------

#if (LUA_VERSION_NUM == 501)

#define luaL_testudata(L, ud, tname)  lsec_testudata(L, ud, tname)
//////// DEFOLD BEGIN
#define setfuncs(L, MOD, R)    luaL_register(L, MOD, R)
//////// DEFOLD END
#define lua_rawlen(L, i)  lua_objlen(L, i)

#ifndef luaL_newlib
//////// DEFOLD BEGIN
#define luaL_newlib(L, MOD, R) do { lua_newtable(L); luaL_register(L, MOD, R); } while(0)
//////// DEFOLD END
#endif

#else
#define setfuncs(L, R) luaL_setfuncs(L, R, 0)
#endif

//------------------------------------------------------------------------------

#if (!defined(LIBRESSL_VERSION_NUMBER) && (OPENSSL_VERSION_NUMBER >= 0x1010000fL))
#define LSEC_ENABLE_DANE
#endif

//------------------------------------------------------------------------------

#if !((defined(LIBRESSL_VERSION_NUMBER) && (LIBRESSL_VERSION_NUMBER < 0x2070000fL)) || (OPENSSL_VERSION_NUMBER < 0x1010000fL))
#define LSEC_API_OPENSSL_1_1_0
#endif

//------------------------------------------------------------------------------

#if !defined(LIBRESSL_VERSION_NUMBER) && ((OPENSSL_VERSION_NUMBER & 0xFFFFF000L) == 0x10101000L || (OPENSSL_VERSION_NUMBER & 0xFFFFF000L) == 0x30000000L)
#define LSEC_OPENSSL_ERRNO_BUG
#endif

//------------------------------------------------------------------------------

#if !defined(LIBRESSL_VERSION_NUMBER) && !defined(OPENSSL_NO_PSK)
#define LSEC_ENABLE_PSK
#endif

//------------------------------------------------------------------------------

#endif
