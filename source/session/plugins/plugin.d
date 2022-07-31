/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.plugin;
import session.plugins;
import session.log;
import lumars;
import bindbc.lua;
import std.path;
import std.file;
import std.string;
import i18n;

private {

    LuaTable createEnvironment(LuaState* state, string name, LuaTable gTable) {
        
        // Create the local global table for the plugin
        LuaTable env = LuaTable.makeNew(state);
        env.push();
        state.setGlobal(name);

        // Set __index = _G for lGlobal
        LuaTable meta = LuaTable.makeNew(state);
        meta.push();
        state.push("__index");
        gTable.push();
        state.rawSet(-3);
        
        // Set meta as our meta table
        env.setMetatable(meta);

        return env;
    }

    // Gets whether a library has been loaded
    bool hasLoadedLibrary(LuaTable table, string name) {
        return table.get!LuaTable("LOADED").get!LuaValue(name).kind == LuaValue.Kind.table;
    }

    // Gets an already loaded library has been loaded
    LuaTable getLoadedLibrary(LuaTable table, string name) {
        return table.get!LuaTable("LOADED").get!LuaTable(name);
    }

    // Sets an already loaded library has been loaded
    void setLoadedLibrary(LuaTable table, string name, LuaTable lib) {
        table.get!LuaTable("LOADED").set(name, lib);
    }
    
    LuaTable require(Plugin plugin, LuaState* state, LuaTable env, string module_, string workingDirectory) {

        // The canonical module name (x.y.z)
        string modCanonicalName = module_.replace("/", ".").replace("\\", ".");

        foreach(element; modCanonicalName.split(".")) {
            if (element.length == 0) {
                plugin.encounteredError = true;
                state.error(_("Attempted to load invalid module specifier %s").format(module_));
                return LuaTable.init;
            }
        }

        // Skip loading from file if a library is already loaded
        if (hasLoadedLibrary(env, modCanonicalName)) {
            return getLoadedLibrary(env, modCanonicalName);
        }

        // Module file in format x/y/z.lua
        string modFile = module_.replace(".", "/").setExtension("lua");

        // Load library from file if a library is already loaded
        string path = buildPath(workingDirectory, modFile);

        // Error out if we can't find the module file
        if (!exists(path))  {
            state.error(_("Module %s not found").format(modCanonicalName));
            return LuaTable.init;
        }

        // Disallow symbolink links
        string testSegments;
        foreach(segment; pathSplitter(modFile)) {
            testSegments = buildPath(testSegments, segment);

            // Do the symlink test
            if (isSymlink(buildPath(workingDirectory, testSegments))) {
                plugin.encounteredError = true;
                state.error(_("Attempted to require a symlink, this is not allowed."));
                return LuaTable.init;
            }
        }

        // We should be safe.
        LuaTable newEnv = state.createEnvironment(modCanonicalName, env);
        state.doString(readText(path), newEnv);
        setLoadedLibrary(env, modCanonicalName, newEnv);
        return newEnv;
    }
}

class Plugin {
private:
    string workingDirectory;
    PluginInfo info;
    LuaState* state;
    LuaTable lGlobal;
    const(char)* cName;
    bool encounteredError;
    bool enabled;
    
    LuaTable createEnvironmentInfo() {
        LuaTable nt = LuaTable.makeNew(state);
        nt.set("id", info.pluginId);
        nt.set("name", info.pluginName);
        nt.set("version", info.pluginVersion);
        return nt;
    }

    LuaTable createEnvironment() {
        
        // Create the local global table for the plugin
        LuaTable env = LuaTable.makeNew(state);
        env.set("PLUGIN_INFO", createEnvironmentInfo());
        env.set("LOADED", LuaTable.makeNew(state));
        env.set("require", (LuaState* state, string module_) {
            return require(this, state, env, module_, workingDirectory);
        });

        // Set global
        env.push();
        state.setGlobal(info.pluginId);

        // Set metatable
        LuaTable meta = LuaTable.makeNew(state);
        meta.push();
        state.push("__index");
        state.getGlobal("_G");
        state.rawSet(-3);
        
        // Set meta as our meta table
        env.setMetatable(meta);

        return env;
    }

public:
    this(PluginInfo info, string workingDirectory, LuaState* state, LuaTable apiTable, bool enabled) {
        this.info = info;
        this.cName = info.pluginName.toStringz;
        this.workingDirectory = workingDirectory;
        this.state = state;
        this.enabled = enabled;

        // Create the local global table for the plugin
        lGlobal = this.createEnvironment();

        // Execute whatever is in init.lua
        state.doString(readText(buildPath(workingDirectory, "init.lua")), lGlobal);
        insLogInfo(_("Loaded plugin %s %s..."), info.pluginName, info.pluginVersion);

        if (enabled) {
            try {
                if (this.hasEvent("onInit")) {
                    this.callEvent("onInit");
                }
            } catch (Exception ex) {

                // Error display for plugins erroring out
                insLogErr(_("%s (plugin): %s"), info.pluginName, ex.msg);
            }
        }
    }

    /**
        Gets whether the plugin has the specified event
    */
    bool hasEvent(string name) {
        return lGlobal.get!LuaValue(name).kind == LuaValue.Kind.func;
    }

    /**
        Calls an event within the plugin
    */
    void callEvent(T...)(string name, T args) {
        if (!isEnabled) return;

        auto top = state.top();

        lGlobal.pushElement(name);
        lGlobal.push();
        if (lua_setfenv(state.handle, -2) == 0) 
            throw new Exception("Failed to set function environment");

        foreach(arg; args) {
            import std.traits : isNumeric;
            static if (is(typeof(arg) == bool)) {
                state.push!bool(arg);
            } else static if (isNumeric!(typeof(arg))) {
                state.push!double(cast(double)arg);
            } else state.push(arg);
        }

        auto status = state.pcall(args.length, 0, 0);
        if (status != LuaStatus.ok) {
            encounteredError = true;
            const error = state.get!string(-1);
            state.pop(state.top()-top);
            throw new Exception(error);
        }
    }

    /**
        Gets the null-terminated form of the name
    */
    const(char)* getCName() {
        return cName;
    }
    
    /**
        Gets whether any errors in the plugin has been encountered.
    */
    bool hasError() {
        return encounteredError;
    }

    /**
        Gets whether the plugin is enabled
    */
    bool isEnabled() {
        return enabled && !encounteredError;
    }

    /**
        Sets whether the plugin is enabled

        NOTE: This will unset the error encounter tag.
        NOTE: This will re-initialize the plugin.
    */
    void isEnabled(bool value) {
        enabled = value;
        encounteredError = false;

        if (enabled) {
            if (this.hasEvent("onInit")) {
                this.callEvent("onInit");
            }
        }
    }

    /**
        Returns the plugin info associated with this plugin
    */
    PluginInfo getInfo() {
        return info;
    }
}

struct PluginInfo {
    string pluginId;
    string pluginName;
    string pluginVersion;
}