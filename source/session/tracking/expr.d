/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.tracking.expr;
import session.tracking;
import session.scene;
import session.log;
import ft;
import inochi2d;
import lumars;
import bindbc.lua : luaL_newstate, luaopen_math, lua_close;
import std.format;
import i18n;
import open_simplex_2.open_simplex_2_f;
import std.random : uniform;

private {
    LuaState* state;
    OpenSimplex2F simplex;
}

void insInitExpressions() {

    simplex = new OpenSimplex2F(uniform(0, ulong.max));

    // The expression system is COMPLETELY sandboxed
    // Having no access to any lua standard library features
    // We're basically registering all the functions here.
    state = new LuaState(luaL_newstate());
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBlendshapeFor(name);
    })("BLEND");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).position.x;
    })("BONE_X");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).position.y;
    })("BONE_Y");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).position.z;
    })("BONE_Z");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).rotation.roll.degrees;
    })("ROLL");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).rotation.pitch.degrees;
    })("PITCH");
    
    state.register!((string name) {
        if (!insScene.space.currentZone) return 0f;
        return insScene.space.currentZone.getBoneFor(name).rotation.yaw.degrees;
    })("YAW");
    
    state.register!(() { return currentTime(); })("time");
    state.register!((float val) { return sin(val); })("sin");
    state.register!((float val) { return cos(val); })("cos");
    state.register!((float val) { return tan(val); })("tan");
    state.register!((float val) { return sinh(val); })("sinh");
    state.register!((float val) { return cosh(val); })("cosh");
    state.register!((float val) { return tanh(val); })("tanh");
    state.register!((float val) { return clamp(sin(val), 0, 1); })("psin");
    state.register!((float val) { return clamp(cos(val), 0, 1); })("pcos");
    state.register!((float val) { return clamp(tan(val), 0, 1); })("ptan");
    state.register!((float val) { return (1.0+sin(val))/2.0; })("usin");
    state.register!((float val) { return (1.0+cos(val))/2.0; })("ucos");
    state.register!((float val) { return (1.0+tan(val))/2.0; })("utan");
    state.register!((float val) { return abs(val); })("abs");
    state.register!((float val) { return sqrt(val); })("sqrt");
    state.register!((float val) { return floor(val); })("floor");
    state.register!((float val) { return ceil(val); })("ceil");
    state.register!((float val) { return round(val); })("round");
    state.register!((float a, float b) { return min(a, b); })("min");
    state.register!((float a, float b) { return max(a, b); })("max");
    state.register!((float x, float min, float max) { return clamp(x, min, max); })("clamp");
    state.register!((float a, float b, float  val) { return lerp(a, b, val); })("lerp");
    state.register!((float x, float tx, float y, float ty, float val) { return hermite(x, tx, y, ty, val); })("cubic");
    state.register!((float y, float x) { return atan2(y, x); })("atan2");
    state.register!((float value) { return degrees(value); })("degrees");
    state.register!((float value) { return radians(value); })("radians");
    state.register!((float val) { return simplex.noise2(val, 0); })("simplex");
    state.register!((float val) { return (1+simplex.noise2(val, 0))/2.0; })("usimplex");
}

void insCleanupExpressions() {
    lua_close(state.handle());
    destroy(state);
}


struct Expression {
private:
    // expression function name
    string exprName_;

    // source
    string expressionSource_;

    // last error
    string lastError_;

    bool updateState() {
        if (expressionSource_.length == 0) {
            lastError_ = "Expression is empty";
            return false;
        }

        try {
            state.doString("function %s() return (%s) end".format(exprName_, expressionSource_));
            lastError_ = null;
            return true;
        } catch(Exception ex) {
            lastError_ = ex.msg;
            return false;
        }
    }

public:

    /**
        Constructs an expression
    */
    this(string signature, string source) {
        insLogInfo("Created expression %s...", signature);
        this.exprName_ = signature;
        this.expressionSource_ = source;
        updateState();
    }

    /**
        Gets the expression to evaluate
    */
    string signature() {
        return exprName_;
    }

    /**
        Gets the expression to evaluate
    */
    string expression() {
        return expressionSource_;
    }

    /**
        Sets the expression to evaluate
    */
    bool expression(string value) {
        expressionSource_ = value;
        return updateState();
    }

    /**
        Gets the last error encounted for the expression
    */
    string lastError() {
        return lastError_;
    }

    float call() {
        if (lastError_.length > 0) return 0f;

        int stackStartPos = state.top();
        int returned = 0;

        try {

            // Attempt call
            state.getGlobal(exprName_);
            if (state.pcall(0, 1, 0) != LuaStatus.ok) {
                lastError_ = state.get!string(-1);
                return 0f;
            }

            returned = state.top() - stackStartPos;


            // Type checking
            auto type = state.type(-1);
            if (type != LuaValue.Kind.number) {
                state.pop(1);
                import std.conv : text;
                lastError_ = _("Expected %s, got %s").format(LuaValue.Kind.number.stringof, type.text);
                return 0;
            }

            // We always want to get the first value returned, in case someone sneakily tries to return multiple.
            float val = state.get!float(-returned);
            state.pop(returned);

            // Value return
            return val;
        
        } catch (Exception ex) {
            state.pop(returned);
            
            // Other error occured.
            lastError_ = ex.msg;
            return 0;
        }
    }
}

string insExpressionGenerateSignature(uint uuid, int axis) {
    return "p%s_%s".format(uuid, axis);
}