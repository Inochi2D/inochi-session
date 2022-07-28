module session.plugins;
public import session.plugins.plugin;
import session.plugins.api;
import inui.core.settings;
import inui.core.path;
import bindbc.lua;
import lumars;
import session.log;
import std.file;
import std.path;

private {
    bool couldLoadLua = true;
    LuaState* state;
    LuaTable apiTable;

    struct PluginRunState {
        bool isEnabled;
    }
}

/**
    Gets the plugin state
*/
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

void insSavePluginState() {
    PluginRunState[string] states;
    foreach(plugin; insPlugins) {
        states[plugin.getInfo().pluginId] = PluginRunState(
            plugin.isEnabled
        );
    }

    inSettingsSet("pluginStates", states);
}

void insEnumeratePlugins() {
    insPlugins.length = 0;

    string pluginsDir = inGetAppCustomPath("plugins");
    insLogInfo("Scanning plugins at %s...", pluginsDir);

    PluginRunState[string] states = inSettingsGet!(PluginRunState[string])("pluginStates");

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
                bool shouldEnable = info.pluginId in states ? states[info.pluginId].isEnabled : true;
                insPlugins ~= new Plugin(info, pluginDir, state, apiTable, shouldEnable);
            } catch (Exception ex) {
                insLogErr("Plugin %s failed to initialize, %s.", pluginDirName, ex.msg);
            }
        } else {
            insLogWarn("Invalid plugin %s...", pluginDirName);
        }
    }

    insSavePluginState();
}

/**
    Gets whether Lua support is loaded.
*/
bool insHasLua() {
    return couldLoadLua;
}

/**
    Gets string of value
*/
string luaValueToString(ref LuaValue value) {
    import std.conv : text;
    import std.format : format;
    switch(value.kind) {
        case LuaValue.Kind.nil:
            return "nil";
        case LuaValue.Kind.number:
            return (cast(double)value).text;
        case LuaValue.Kind.text:
            return (cast(string)value);
        case LuaValue.Kind.boolean:
            return (cast(bool)value).text;
        default:
            return "(%s)".format(value.kind);
    }
}