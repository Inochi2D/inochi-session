/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.api.base;
import lumars;
import bindbc.lua;
import std.string;
import std.meta : AliasSeq;
import std.conv : text;
import session.log;
import std.stdio;

private {
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
        if (state.callMetamethod(1, "__tostring")) return 1;

        if (state.top() > 0) state.push!string(idxToString(state, state.top()));
        else state.push!LuaNil(LuaNil.init);
        return 1;
    }

    extern(C)
    int l_tonumber(lua_State* lstate) {
        import std.conv : to, ConvException;
        import std.uni : isNumber;
        auto state = new LuaState(lstate);
        long base = state.optInt(2, 10);
        if (base == 10) {
            state.checkAny(1);
            auto value = state.get!LuaValue(1);
            
            if (value.kind == LuaValue.Kind.text) {
                try {
                    state.push!double(to!double((cast(string)value).strip));
                    return 1;
                } catch (ConvException ex) { } // Ignore error and fall back to pushing nil
            }

            if (value.kind == LuaValue.Kind.number) {
                state.push!double(cast(double)value);
                return 1;
            }
        } else {
            state.checkArg(2 <= base && base <= 36, 2, "base out of range");
            auto value = state.checkString(1).strip;
            if (value[0].isNumber) {
                try {
                    long lvalue = value.to!long(cast(int)base);
                    state.push!long(lvalue);
                    return 1;
                } catch (ConvException ex) { } // Ignore error and fall back to pushing nil
            }
        }
        state.push!LuaNil(LuaNil.init);
        return 1;
    }

    string l_type(LuaState* s, LuaValue v) {
        return text(v.kind);
    }

    extern(C)
    int l_assert(lua_State* lstate) {
        auto state = new LuaState(lstate);
        state.checkAny(1);
        if (!state.get!bool(1)) {
            state.error(luaL_optstring(state.handle, 2, "assertation failed!").fromStringz);
            return 0;
        }
        return 0;
    }
}

void insRegisterBaseAPI(LuaState* state) {
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
    state.push(cast(lua_CFunction)&l_tostring);
    state.setGlobal("tonumber");
    state.push(cast(lua_CFunction)&l_assert);
    state.setGlobal("assert");
    state.push(&l_type);
    state.setGlobal("type");
}
