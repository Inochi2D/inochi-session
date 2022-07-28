module session.plugins;
public import session.plugins.plugin;
import session.plugins.api;
import bindbc.lua;
import lumars;
import session.log;
import inui.core.path;
import std.file;
import std.path;

private {
    bool couldLoadLua = true;
    LuaState* state;
    LuaTable apiTable;
}

Plugin[] insPlugins;

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

    // Create Lua state
    state = new LuaState(luaL_newstate());

    // Set _G table
    state.copy(LUA_GLOBALSINDEX);
    state.setGlobal("_G");

    insPluginRegisterAll(state);
    insEnumeratePlugins();
}

void insEnumeratePlugins() {
    insPlugins.length = 0;

    string pluginsDir = inGetAppCustomPath("plugins");
    insLogInfo("Scanning plugins at %s...", pluginsDir);

    foreach(pluginDir; dirEntries(pluginsDir, SpanMode.shallow, false)) {
        string initFile = buildPath(pluginDir, "init.lua");
        string infoFile = buildPath(pluginDir, "info.lua");
        string pluginDirName = baseName(pluginDir);

        if (initFile.exists && infoFile.exists) {

            // We always just want a Lua table, as such we inject the return statement
            // here automatically. It's cursed, I know.
            state.doString("return "~readText(infoFile));
            try {

                // Get plugin information
                PluginInfo info = state.get!PluginInfo(-1);
                state.pop(2);

                // Ignore whatever the user sets.
                info.pluginId = pluginDirName;

                // Add plugin
                insPlugins ~= new Plugin(info, pluginDir, state, apiTable);
            } catch (Exception ex) {
                insLogErr("Plugin %s failed to initialize, %s.", pluginDirName, ex.msg);
            }
        } else {
            insLogWarn("Invalid plugin %s...", pluginDirName);
        }
    }
}

/**
    Gets whether Lua support is loaded.
*/
bool insHasLua() {
    return couldLoadLua;
}