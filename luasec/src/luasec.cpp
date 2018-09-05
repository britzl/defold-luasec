

#if defined(WIN32)
#include <WinSock2.h>
#include <Windows.h>
#endif

// include the Defold SDK
#include <dmsdk/sdk.h>
#include "config.h"

#if defined(DM_PLATFORM_HTML5) != true
#include "ssl.h"
#include "context.h"
#include "x509.h"

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    luaopen_ssl_core(L);
    //printf("%d\n", lua_gettop(L));
    lua_pop(L, 4);

    luaopen_ssl_context(L);
    //printf("%d\n", lua_gettop(L));
    lua_pop(L, 5);

    luaopen_ssl_x509(L);
    //printf("%d\n", lua_gettop(L));
    lua_pop(L, 3);

    assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeMyExtension(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeMyExtension(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);

    printf("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeMyExtension(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeMyExtension(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}


// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

DM_DECLARE_EXTENSION(LuaSec, LIB_NAME, AppInitializeMyExtension, AppFinalizeMyExtension, InitializeMyExtension, 0, 0, FinalizeMyExtension)

#else



dmExtension::Result AppInitializeMyExtension(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeMyExtension(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeMyExtension(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeMyExtension(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(LuaSec, LIB_NAME, AppInitializeMyExtension, AppFinalizeMyExtension, InitializeMyExtension, 0, 0, FinalizeMyExtension)
#endif
