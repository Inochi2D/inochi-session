/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.api;
import lumars;

public import session.plugins.api.base;
public import session.plugins.api.scene;
public import session.plugins.api.ui;

void insPluginRegisterAll(LuaState* state) {
    insRegisterBaseAPI(state);
    insRegisterSceneAPI(state);
    insRegisterUIAPI(state);
}