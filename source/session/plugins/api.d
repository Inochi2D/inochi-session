/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.api;
import lumars;
import bindbc.lua;
import std.string;
import inui.widgets;
import std.meta : AliasSeq;
import std.stdio;
import std.conv : text;
import session.log;

private {
    alias GUI_API = AliasSeq!(
        "button", (string text) { return uiImButton(text.toStringz); },
        "label", (string text) { uiImLabel(text); },
        "error", (string title, string text) { uiImDialog(title.toStringz, text); },
        "info", (string title, string text) { uiImDialog(title.toStringz, text, DialogLevel.Info); },
        "warn", (string title, string text) { uiImDialog(title.toStringz, text, DialogLevel.Warning); },
    );

    string idxToString(LuaState* state, int i) {
        switch(state.type(i)) {
            case LuaValue.Kind.nil:
                return "nil";
            case LuaValue.Kind.number:
                return state.get!double(i).text;
            case LuaValue.Kind.text:
                return state.get!string(i);
            case LuaValue.Kind.boolean:
                return state.get!bool(i).text;
            default:
                return "%s: %x".format(state.type(i).text, lua_topointer(state.handle, i));
        }
    }

    extern(C)
    string printGetOutString(lua_State* lstate) {
        auto state = new LuaState(lstate);

        string outString;
        int n = state.top();
        foreach(i; 1..n+1) {
            if (i > 1) outString ~= "\t";
            outString ~= idxToString(state, i);
        }
        state.pop(n);
        return outString;
    }

    extern(C)
    int l_print(lua_State* lstate) {
        writeln(printGetOutString(lstate));
        return 0;
    }

    extern(C)
    int l_info(lua_State* lstate) {
        insLogInfo(printGetOutString(lstate));
        return 0;
    }

    extern(C)
    int l_warn(lua_State* lstate) {
        insLogWarn(printGetOutString(lstate));
        return 0;
    }

    extern(C)
    int l_err(lua_State* lstate) {
        insLogErr(printGetOutString(lstate));
        return 0;
    }

    extern(C)
    int l_tostring(lua_State* lstate) {
        auto state = new LuaState(lstate);
        if (state.top() > 0) state.push!string(idxToString(state, state.top()));
        else state.push!LuaNil(LuaNil.init);
        return 1;
    }
}

void inPluginRegisterAll(LuaState* state) {

    // Push all the APIs in
    state.register!GUI_API("ui");

    state.push(cast(lua_CFunction)&l_print);
    state.setGlobal("print");
    state.push(cast(lua_CFunction)&l_info);
    state.setGlobal("info");
    state.push(cast(lua_CFunction)&l_warn);
    state.setGlobal("warn");
    state.push(cast(lua_CFunction)&l_err);
    state.setGlobal("err");

    state.push(cast(lua_CFunction)&l_tostring);
    state.setGlobal("tostring");
}