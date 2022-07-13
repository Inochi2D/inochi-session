module session.tracking.sources.expr;
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

/**
    A tracking data source that uses Lua expressions to compute a 
    final blendshape value
*/
class ExpressionSource : IBindingSource {
public:
    /**
        List of expressions
    */
    Expression[string] expressions;
    
    /**
        Initialize state
    */
    this() {
        initState();
    }
    
    /**
        Gets the source ID
    */
    string getSourceID() {
        return "Expression";
    }

    /**
        Returns a list of keys for the source
    */
    string[] getBlendshapeKeys() {
        return expressions.keys;
    }

    /**
        Returns the value for the specified name
    */
    float getBlendshape(string name) {
        return expressions[name].call();
    }

    /**
        Gets list of keys for bones
    */
    string[] getBoneKeys() {
        return null;
    }

    /**
        Gets a bone
    */
    ref Bone getBone(string name) {
        throw new Exception("Can't get bones from expression source");
    }

    /**
        Clears the source
    */
    void clear() {
        destroy(state);
        initState();
    }
}