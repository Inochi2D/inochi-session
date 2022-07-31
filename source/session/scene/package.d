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
import session.plugins;

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
    trashcanTexture = new Texture(ShallowTexture(cast(ubyte[])import("tex/ui-delete.png")));
}

void insSceneCleanup() {
    insSaveVSpace(insScene.space);

    foreach(ref source; insScene.space.getAllSources()) {
        if (source) {
            if (source.isRunning()) {
                source.stop();
            }
            destroy(source);
        }
    }
}

void insUpdateScene() {
    inUpdate();

    // Update virtual spaces
    insScene.space.update();

    inBeginScene();

        // Trashcan render variables
        float trashcanScale = 1f;
        float sizeOffset = 0f;
        vec2 centerOffset = inCamera.getCenterOffset;
        vec2 trashcanPos = vec2(
            (inCamera.position.x-centerOffset.x)+TRASHCAN_DISPLACEMENT,
            (inCamera.position.y+centerOffset.y)-(trashcanSize+TRASHCAN_DISPLACEMENT)
        );

        if (isMouseOverDelete) {
            float scalePercent = (sin(currentTime()*2)+1)/2;
            trashcanScale += 0.15*scalePercent;
            sizeOffset = ((trashcanSize*trashcanScale)-trashcanSize)/2;
        }

        // Draw trashcan
        inDrawTextureAtRect(
            trashcanTexture, 
            rect(
                trashcanPos.x-sizeOffset, 
                trashcanPos.y-sizeOffset, 
                trashcanSize*trashcanScale, 
                trashcanSize*trashcanScale
            ), 
            rect(0, 0, 1, 1), 
            trashcanVisibility
        );
        
        // Update plugins
        foreach(ref plugin; insPlugins) {
            if (!plugin.isEnabled) continue;

            if (plugin.hasEvent("onUpdate")) {
                plugin.callEvent("onUpdate", deltaTime());
            }
        }

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

    trashcanVisibility = dampen(trashcanVisibility, isDragDown ? 0.85 : 0, deltaTime(), 1);
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
    vec2 targetSize = vec2(0);

    bool isDragDown = false;
    Camera inCamera;

    enum TRASHCAN_DISPLACEMENT = 16;
    float trashcanVisibility = 0;
    float trashcanSize = 128;
    Texture trashcanTexture;
    rect deleteArea;
    bool isMouseOverDelete;
}

void insInteractWithScene() {
    int width, height;
    inGetViewport(width, height);
    
    float trashcanHalfSize = trashcanSize/2;
    deleteArea = rect(0, height-(TRASHCAN_DISPLACEMENT+trashcanHalfSize), trashcanHalfSize+TRASHCAN_DISPLACEMENT, trashcanHalfSize+TRASHCAN_DISPLACEMENT);
    isMouseOverDelete = deleteArea.intersects(inInputMousePosition());

    import std.stdio : writeln;
    inCamera = inGetCamera();
    vec2 mousePos = inInputMousePosition();
    vec2 mouseOffset = vec2(width/2, height/2);
    vec2 cameraCenter = inCamera.getCenterOffset();
    mousePos = vec2(
        vec4(
            (mousePos.x-mouseOffset.x+inCamera.position.x)/inCamera.scale.x,
            (mousePos.y-mouseOffset.y+inCamera.position.y)/inCamera.scale.y,
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
                        targetSize = size;
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
        float prevScale = targetScale;

        float targetDelta = (inInputMouseScrollDelta()*0.05)*(1-clamp(targetScale, 0, 0.45));
        targetScale = clamp(
            targetScale+targetDelta, 
            0.25,
            5
        );
        
        if (targetScale != prevScale) {
            inSetUpdateBounds(true);
                vec4 lbounds = draggingPuppet.root.getCombinedBounds!true();
                vec2 tl = vec4(lbounds.xy, 0, 1);
                vec2 br = vec4(lbounds.zw, 0, 1);
                targetSize = abs(br-tl);
            inSetUpdateBounds(false);
        }
    }

    // Model Movement
    if (inInputMouseDragging(MouseButton.Left) && hasDonePuppetSelect && draggingPuppet) {
        vec2 delta = inInputMouseDragDelta(MouseButton.Left);
        targetPos = vec2(
            draggingPuppetStartPos.x+delta.x/inCamera.scale.x, 
            draggingPuppetStartPos.y+delta.y/inCamera.scale.y, 
        );
    }
    
    // Model clamping
    {
        float camPosClampX = (cameraCenter.x*2)+(targetSize.x/3);
        float camPosClampY = (cameraCenter.y*2)+(targetSize.y/1.5);

        // Clamp model to be within viewport
        targetPos.x = clamp(
            targetPos.x,
            (inCamera.position.x-camPosClampX)*inCamera.scale.x,
            (inCamera.position.x+camPosClampX)*inCamera.scale.x
        );
        targetPos.y = clamp(
            targetPos.y,
            (inCamera.position.y-camPosClampY)*inCamera.scale.y,
            (inCamera.position.y+camPosClampY)*inCamera.scale.y
        );
    }

    // Apply Movement + Scaling
    if (draggingPuppet) {
        if (isMouseOverDelete) {

            // If the mouse was let go
            if (isDragDown && !inInputMouseDown(MouseButton.Left)) {
                if (selectedPuppet >= 0 && selectedPuppet < insScene.sceneItems.length) {
                    
                    import std.algorithm.mutation : remove;
                    insScene.sceneItems = insScene.sceneItems.remove(selectedPuppet);
                    draggingPuppet = null;
                    selectedPuppet = -1;
                    isDragDown = false;
                    return;
                }
            }
        }

        isDragDown = inInputMouseDown(MouseButton.Left);

        import bindbc.imgui : igIsKeyDown, ImGuiKey;
        if (igIsKeyDown(ImGuiKey.LeftCtrl) || igIsKeyDown(ImGuiKey.RightCtrl)) {
            float targetDelta = (inInputMouseScrollDelta()*0.05)*(1-clamp(targetScale, 0, 0.45));
            targetScale = clamp(
                targetScale+targetDelta, 
                0.25,
                5
            );
        }
        

        if (isDragDown && isMouseOverDelete) {
            

            draggingPuppet.root.localTransform.translation = dampen(
                draggingPuppet.root.localTransform.translation,
                vec3(
                    (inCamera.position.x+(-cameraCenter.x)+128), 
                    (inCamera.position.y+(cameraCenter.y)-128), 
                    0
                ),
                inGetDeltaTime()
            );

            // Dampen & clamp scaling
            draggingPuppet.root.localTransform.scale = dampen(
                draggingPuppet.root.localTransform.scale,
                vec2(0.025),
                inGetDeltaTime()
            );
        } else {

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
}