/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.plugin;
import session.log;
import lumars;
import bindbc.lua;
import std.path;
import std.file;
import std.string;
import i18n;

class Plugin {
private:
    string workingDirectory;
    PluginInfo info;
    LuaState* state;
    LuaTable lGlobal;
    const(char)* cName;
    bool encounteredError;

public:

    this(PluginInfo info, string workingDirectory, LuaState* state, LuaTable apiTable) {
        this.info = info;
        this.cName = info.pluginName.toStringz;
        this.workingDirectory = workingDirectory;
        this.state = state;

        // Create the local global table for the plugin
        lGlobal = LuaTable.makeNew(state);
        lGlobal.push();
        state.setGlobal(info.pluginId);

        // Set __index = _G for lGlobal
        LuaTable meta = LuaTable.makeNew(state);
        lGlobal.push();
        meta.push();
        state.push("__index");
        state.getGlobal("_G");
        state.rawSet(-3);
        state.pop(1);
        
        // Set meta as our meta table
        lGlobal.setMetatable(meta);
        state.pop(1);


        // Execute whatever is in init.lua
        state.doString(readText(buildPath(workingDirectory, "init.lua")), lGlobal);
        insLogInfo(_("Loaded plugin %s %s..."), info.pluginName, info.pluginVersion);

        try {
            if (this.hasEvent("onInit")) {
                this.callEvent("onInit");
            }
        } catch (Exception ex) {

            // Error display for plugins erroring out
            insLogErr(_("%s (plugin): %s"), info.pluginName, ex.msg);
        }
    }

    void require(string file) {
        string path = buildPath(workingDirectory, file);
        state.doString(readText(path), lGlobal);
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