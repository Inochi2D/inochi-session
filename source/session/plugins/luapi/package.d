module session.plugins.luapi;
import bindbc.lua;
import session.log;

private {
    bool couldLoadLua = true;
}

/**
    Initializes Lua support
*/
void insLuaInit() {
    // LuaSupport support = loadLua();

    // if (support == LuaSupport.noLibrary || support == LuaSupport.badLibrary) {
    //     couldLoadLua = false;
    //     insLogWarn("Could not load Lua support...");
    // } else insLogInfo("Lua support initialized.");
    insLogInfo("Lua support initialized. (Statically linked for now)");
}

/**
    Gets whether Lua support is loaded.
*/
bool insHasLua() {
    return couldLoadLua;
}