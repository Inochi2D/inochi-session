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

/**
    List of puppets
*/
Puppet[] insPuppets;

void insUpdateScene() {
    inBeginScene();
        foreach(ref puppet; insPuppets) {
            puppet.update();
            puppet.draw();
        }
    inEndScene();
}

private {
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
                foreach(ref puppet; insPuppets) {

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
                    }
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
        targetScale = draggingPuppet.root.localTransform.scale.x+(inInputMouseScrollDelta());
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
        draggingPuppet.root.localTransform.scale = vec2(
            clamp(
                draggingPuppet.root.localTransform.scale.x,
                0.25,
                1000
            )
        );
    }
}