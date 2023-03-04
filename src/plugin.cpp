#include <Windows.h>
#include <iostream>
#include <string>

#include <reframework/API.hpp>
#include <sol/sol.hpp>
#include <cpr/cpr.h>

#include "plugin.hpp"

lua_State* g_lua{ nullptr };

//https://github.com/uNetworking/uWebSockets

void on_lua_state_created(lua_State* l) {
    reframework::API::LuaLock _{};

    g_lua = l;
    sol::state_view lua{ g_lua };

    auto lua_object = lua.create_table();
    lua_object["upload"] = [](const std::string &json, const std::function<void(std::string)> &callback) {
        /*cpr::Post(
            cpr::Url{ "" }, 
            cpr::Header{{ "Content-Type", "application/json" }}, 
            cpr::Body{ json }
        );*/

        callback(json);
    };

    lua["mhl"] = lua_object;
}

void on_lua_state_destroyed(lua_State* l) {
    reframework::API::LuaLock _{};

    g_lua = nullptr;
}

extern "C" __declspec(dllexport) void reframework_plugin_required_version(REFrameworkPluginVersion *version) {
    version->major = REFRAMEWORK_PLUGIN_VERSION_MAJOR;
    version->minor = REFRAMEWORK_PLUGIN_VERSION_MINOR;
    version->patch = REFRAMEWORK_PLUGIN_VERSION_PATCH;

    // Optionally, specify a specific game name that this plugin is compatible with.
    version->game_name = "MHRISE";
}

extern "C" __declspec(dllexport) bool reframework_plugin_initialize(const REFrameworkPluginInitializeParam *param) {
    reframework::API::initialize(param);

    const auto functions = param->functions;
    functions->on_lua_state_created(on_lua_state_created);
    functions->on_lua_state_destroyed(on_lua_state_destroyed);

    return true;
}