module session.tracking.expr;
import session.tracking;
import ft;
import inochi2d;
import lumars;
import bindbc.lua : luaL_newstate, luaopen_math;
import std.format;

private {
    LuaState* state;

    void initState() {
        state = new LuaState(luaL_newstate());
        luaopen_math(state.handle);
    }
}


struct Expression {
private:
    // expression function name
    string exprName_;

    // source
    string expressionSource_;

public:
    this(string signature, string source) {
        this.exprName_ = signature;
        this.expressionSource_ = source;
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
    void expression(string value) {
        expressionSource_ = value;
        state.doString("function %s() return (%s) end".format(exprName_, expressionSource_));
    }

    float call() {
        state.push(exprName_);
        state.call(0, 1);
        return state.get!float(-1);
    }
}