/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.api.scene;
import lumars;
import std.string;
import std.meta : AliasSeq;
import session.scene;


private {
    struct PuppetRef {
    private:
        size_t index;
        uint uuid;
    public:

    }

    alias SCENE_API = AliasSeq!(
    );
}

void insRegisterSceneAPI(LuaState* state) {
    state.register!SCENE_API("scene");
}

