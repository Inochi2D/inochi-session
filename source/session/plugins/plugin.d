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

class Plugin {
private:
    string workingDirectory;
    PluginInfo info;
    LuaState* state;
    LuaTable lGlobal;

public:

    this(PluginInfo info, string workingDirectory, LuaState* state, LuaTable apiTable) {
        this.info = info;
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
        insLogInfo("Loaded plugin %s %s...", info.pluginName, info.pluginVersion);
    
        this.callEvent("myEvent", "a", 293595);
        insLogInfo("has myEvent=%s", this.hasEvent("myEvent"));
        insLogInfo("has xEvent=%s", this.hasEvent("xEvent"));
    }

    bool hasEvent(string name) {
        return lGlobal.get!LuaValue(name).kind == LuaValue.Kind.func;
    }

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
            const error = state.get!string(-1);
            state.pop(state.top()-top);
            throw new Exception(error);
        }
    }
    
}

struct PluginInfo {
    string pluginId;
    string pluginName;
    string pluginVersion;
}