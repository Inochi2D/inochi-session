module session.tracking.expr;
import session.tracking;
import session.scene;
import session.log;
import ft;
import inochi2d;
import lumars;
import bindbc.lua : luaL_newstate, luaopen_math;
import std.format;
import i18n;

private {
    LuaState* state;
}

void insInitExpressions() {

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
    
    state.register!(() {
        return currentTime();
    })("time");
    
    state.register!((float val) {
        return sin(val);
    })("sin");
    
    state.register!((float val) {
        return cos(val);
    })("cos");

    state.register!((float val) {
        return tan(val);
    })("tan");
}

void insCleanupExpressions() {
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

        try {

            // Attempt call
            state.getGlobal(exprName_);
            if (state.pcall(0, 1, 0) != LuaStatus.ok) {
                lastError_ = state.get!string(-1);
                return 0f;
            }

            // Type checking
            auto type = state.type(-1);
            if (type != LuaValue.Kind.number) {
                import std.conv : text;
                lastError_ = _("Expected %s, got %s").format(LuaValue.Kind.number.stringof, type.text);
                return 0;
            }

            // Value return
            return state.get!float(-1);
        
        } catch (Exception ex) {
            
            // Other error occured.
            lastError_ = ex.msg;
            return 0;
        }
    }
}

string insExpressionGenerateSignature(Parameter param, int axis) {
    return "p%s_%s".format(param.uuid, axis);
}