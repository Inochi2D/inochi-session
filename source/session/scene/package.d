/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.scene;
import inochi2d;
import inmath;
import inui.input;
import inui;
import session.tracking;
import session.tracking.vspace;
import session.panels.tracking : insTrackingPanelRefresh;
import session.log;
import std.string;

struct Scene {
    VirtualSpace space;

    SceneItem[] sceneItems;
}

struct SceneItem {
    string filePath;
    Puppet puppet;
    TrackingBinding[] bindings;

    void saveBindings() {
        puppet.extData["com.inochi2d.inochi-session.bindings"] = cast(ubyte[])serializeToJson(bindings);
        inWriteINPPuppet(puppet, filePath);
    }

    bool tryLoadBindings() {
        if ("com.inochi2d.inochi-session.bindings" in puppet.extData) {
            bindings = deserialize!(TrackingBinding[])(cast(string)puppet.extData["com.inochi2d.inochi-session.bindings"]);

            // finalize the loading
            foreach(ref binding; bindings) binding.finalize(puppet);            
            return true;
        }
        return false;
    }

    void genBindings() {
        // Reset bindings
        bindings.length = 0;

        struct LinkSrcDst {
            Parameter src;
            Parameter dst;
            int inAxis;
            int outAxis;
        }
        LinkSrcDst[] srcDst;

        foreach(param; puppet.parameters) {
            foreach(ref ParamLink link; param.links) {
                srcDst ~= LinkSrcDst(param, link.link, cast(int)link.outAxis);
            }
        }

        bool isParamAxisLinked(Parameter dst, int axis) {
            foreach(ref LinkSrcDst link; srcDst) {
                if (link.dst == dst && axis == link.outAxis) return true;
            }
            return false;
        }

        mforeach: foreach(ref Parameter param; puppet.parameters) {

            // Skip all params affected by physics
            foreach(ref Driver driver; puppet.getDrivers()) 
                if (driver.affectsParameter(param)) continue mforeach;
            

            // Loop over X/Y for parameter
            int imax = param.isVec2 ? 2 : 1;
            for (int i = 0; i < imax; i++) {
                if (isParamAxisLinked(param, i)) continue;
                
                TrackingBinding binding = new TrackingBinding();
                binding.param = param;
                binding.axis = i;
                binding.type = BindingType.RatioBinding;
                binding.inRange = vec2(0, 1);
                binding.outRange = vec2(0, 1);

                // binding name assignment
                if (param.isVec2) binding.name = "%s (%s)".format(param.name, i == 0 ? "X" : "Y");
                else binding.name = param.name;

                bindings ~= binding;
            }
        }
    }
}

/**
    List of puppets
*/
Scene insScene;

void insSceneAddPuppet(string path, Puppet puppet) {

    import std.format : format;
    SceneItem item;
    item.filePath = path;
    item.puppet = puppet;
    if (!item.tryLoadBindings()) {
        item.genBindings();
    }

    insScene.sceneItems ~= item;
}

void insSceneInit() {
    insScene.space = insLoadVSpace();
}

void insSceneCleanup() {
    insSaveVSpace(insScene.space);

    foreach(ref source; insScene.space.getAllSources()) {
        if (source) destroy(source);
    }
}

void insUpdateScene() {
    inUpdate();

    // Update virtual spaces
    insScene.space.update();

    inBeginScene();
        

        // Update every scene item
        foreach(ref sceneItem; insScene.sceneItems) {
            foreach(ref binding; sceneItem.bindings) {
                binding.update();
            }

            sceneItem.puppet.update();
            sceneItem.puppet.draw();
            
            foreach(ref binding; sceneItem.bindings) {
                binding.lateUpdate();
            }
        }
    inEndScene();
}

/**
    Returns a pointer to the active scene item
*/
SceneItem* insSceneSelectedSceneItem() {
    if (selectedPuppet < 0 || selectedPuppet > insScene.sceneItems.length) return null;
    return &insScene.sceneItems[selectedPuppet];
}

private {
    ptrdiff_t selectedPuppet = -1;
    Puppet draggingPuppet;
    vec2 draggingPuppetStartPos;
    bool hasDonePuppetSelect;
    vec2 targetPos = vec2(0);
    float targetScale = 0;
}

void insInteractWithScene() {
    int width, height;
    inGetViewport(width, height);

    import std.stdio : writeln;
    Camera camera = inGetCamera();
    vec2 mousePos = inInputMousePosition();
    vec2 mouseOffset = vec2(width/2, height/2);
    mousePos = vec2(
        vec4(
            (mousePos.x-mouseOffset.x+camera.position.x)/camera.scale.x,
            (mousePos.y-mouseOffset.y+camera.position.y)/camera.scale.y,
            0, 
            1
        )
    );

    if (inInputMouseDown(MouseButton.Left)) {

        // One shot check if there's a puppet to drag under the cursor
        if (!hasDonePuppetSelect) {
            hasDonePuppetSelect = true;
            draggingPuppet = null;

            // For performance sake we should disable bounds calculation after we're done getting drag state.
            inSetUpdateBounds(true);
                bool selectedAny = false;
                foreach(i, ref sceneItem; insScene.sceneItems) {

                    auto puppet = sceneItem.puppet;

                    // Calculate on-screen bounds of the object
                    vec4 lbounds = puppet.root.getCombinedBounds!true();
                    vec2 tl = vec4(lbounds.xy, 0, 1);
                    vec2 br = vec4(lbounds.zw, 0, 1);
                    vec2 size = abs(br-tl);
                    rect bounds = rect(tl.x, tl.y, size.x, size.y);

                    if (bounds.intersects(mousePos)) {
                        draggingPuppetStartPos = puppet.root.localTransform.translation.xy;
                        targetScale = puppet.root.localTransform.scale.x;
                        targetPos = draggingPuppetStartPos;
                        draggingPuppet = puppet;
                        selectedPuppet = i;
                        selectedAny = true;
                        insTrackingPanelRefresh();
                    }
                }
                if (!selectedAny) {
                    selectedPuppet = -1;
                    draggingPuppet = null;
                    insTrackingPanelRefresh();
                }
            inSetUpdateBounds(false);
            
        }
    } else if (hasDonePuppetSelect) {
        hasDonePuppetSelect = false;
    }

    // Model Scaling
    if (hasDonePuppetSelect && draggingPuppet) {
        import bindbc.imgui : igSetMouseCursor, ImGuiMouseCursor;
        igSetMouseCursor(ImGuiMouseCursor.Hand);
        targetScale = clamp(
            draggingPuppet.root.localTransform.scale.x+(inInputMouseScrollDelta()), 
            0.25,
            1000
        );
    }

    // Model Movement
    if (inInputMouseDragging(MouseButton.Left) && hasDonePuppetSelect && draggingPuppet) {
        vec2 delta = inInputMouseDragDelta(MouseButton.Left);
        targetPos = vec2(
            draggingPuppetStartPos.x+delta.x/camera.scale.x, 
            draggingPuppetStartPos.y+delta.y/camera.scale.y, 
        );
    }
    
    // Apply Movement + Scaling
    if (draggingPuppet) {

        import bindbc.imgui : igIsKeyDown, ImGuiKey;
        if (igIsKeyDown(ImGuiKey.LeftCtrl) || igIsKeyDown(ImGuiKey.RightCtrl)) {
            targetScale = clamp(
                draggingPuppet.root.localTransform.scale.x+(inInputMouseScrollDelta()), 
                0.25,
                1000
            );
        }

        draggingPuppet.root.localTransform.translation = dampen(
            draggingPuppet.root.localTransform.translation,
            vec3(targetPos, 0),
            inGetDeltaTime()
        );

        // Dampen & clamp scaling
        draggingPuppet.root.localTransform.scale = dampen(
            draggingPuppet.root.localTransform.scale,
            vec2(targetScale),
            inGetDeltaTime()
        );
    }
}