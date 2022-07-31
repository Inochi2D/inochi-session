/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.panels.tracking;
import session.tracking.expr;
import inui.panel;
import i18n;
import session.scene;
import session.tracking;
import inui;
import inui.widgets;
import session.log;
import inmath;
import std.string;
import std.uni;
import std.algorithm.searching;

private {
    string trackingFilter;
    const(char)*[] paramNames;

    struct TrackingSource {
        bool isBone;
        string name;
        const(char)* cName;
    }
}

// Refreshes the tracking bindings listed in the tracking panel (headers)
void insTrackingPanelRefresh() {
    trackingFilter = "";
    paramNames = null;    
    if (insSceneSelectedSceneItem()) {
        foreach(ref TrackingBinding binding; insSceneSelectedSceneItem().bindings) {
            paramNames ~= binding.param.name.toStringz;
        }
    }
}

class TrackingPanel : Panel {
private:
    TrackingSource[] sources;
    string[] indexableSourceNames;

    // Refreshes the list of tracking sources
    void refresh(ref TrackingBinding[] trackingBindings) {
        auto blendshapes = insScene.space.getAllBlendshapeNames();
        auto bones = insScene.space.getAllBoneNames();
        
        sources.length = blendshapes.length + bones.length;
        indexableSourceNames.length = sources.length;

        foreach(i, blendshape; blendshapes) {
            sources[i] = TrackingSource(
                false,
                blendshape,
                blendshape.toStringz
            );
            indexableSourceNames[i] = blendshape.toLower;
        }

        foreach(i, bone; bones) {
            sources[blendshapes.length+i] = TrackingSource(
                true,
                bone,
                bone.toStringz
            );

            indexableSourceNames[blendshapes.length+i] = bone.toLower;
        }

        // Add any bindings unnacounted for which are stored in the model.
        trkMain: foreach(bind; trackingBindings) {
            
            // Skip non-existent sources
            if (bind.sourceName.length == 0) continue;

            TrackingSource src = TrackingSource(
                bind.sourceType != SourceType.Blendshape,
                bind.sourceName,
                bind.sourceName.toStringz
            );

            // Skip anything we already know
            foreach(xsrc; sources) {
                if (xsrc.isBone == src.isBone && xsrc.name == src.name) continue trkMain;
            }

            sources ~= src;
            indexableSourceNames ~= src.name.toLower;
        }
    }

    
    // Settings popup for binding types
    pragma(inline, true)
    void settingsPopup(ref TrackingBinding binding) {
        uiImRightClickPopup("BINDING_SETTINGS");

        if (uiImBeginPopup("BINDING_SETTINGS")) {
            if (uiImBeginMenu(__("Type"))) {

                if (uiImMenuItem(__("Ratio Binding"))) {
                    binding.expr = null;
                    binding.type = BindingType.RatioBinding;
                }

                if (uiImMenuItem(__("Expression Binding"))) {
                    binding.expr = new Expression(insExpressionGenerateSignature(cast(int)binding.hashOf(), binding.axis), "");
                    binding.type = BindingType.ExpressionBinding;
                }

                uiImEndMenu();
            }
            uiImEndPopup();
        }
    }

    // Configuration panel for expression bindings
    void exprBinding(size_t i, ref TrackingBinding binding) {
        if (binding.expr) {
            string buf = binding.expr.expression;
            
            uiImLabel(_("Dampen"));
            uiImDrag(binding.dampenLevel, 0, 10);

            if (uiImInputText("###EXPRESSION", buf)) {
                binding.expr.expression = buf;
            }

            uiImLabel(_("Output (%s)").format(binding.outVal));
            uiImIndent();
                uiImProgress(binding.outVal);
            

                uiImPushTextWrapPos();
                    if (binding.expr.lastError.length > 0) {
                        uiImLabelColored(binding.expr.lastError, vec4(1, 0.4, 0.4, 1));
                        uiImNewLine();
                    }

                    if (binding.outVal < 0 || binding.outVal > 1) {
                        uiImLabelColored(_("Value out of range, clamped to 0..1 range."), vec4(0.95, 0.88, 0.62, 1));
                        uiImNewLine();
                    }
                uiImPopTextWrapPos();
            uiImUnindent();
        }
    }

    // Configuration panel for ratio bindings
    void ratioBinding(size_t i, ref TrackingBinding binding) {
        bool hasTrackingSrc = binding.sourceName.length > 0;

        if (hasTrackingSrc && uiImButton(__("Reset"))) {
            binding.sourceName = null;
        }

        if (uiImBeginComboBox(hasTrackingSrc ? binding.sourceDisplayName.toStringz : __("Not tracked"))) {
            if (uiImInputText("###FILTER", uiImAvailableSpace().x, trackingFilter)) {
                trackingFilter = trackingFilter.toLower();
            }

            uiImDummy(vec2(0, 8));

            
            foreach(ix, source; sources) {
                
                if (trackingFilter.length > 0 && !indexableSourceNames[ix].canFind(trackingFilter)) continue;

                bool selected = binding.sourceName == source.name;
                bool nameValid = source.name.length > 0;
                if (source.isBone) {
                    if (uiImBeginMenu(source.cName)) {
                        if (uiImMenuItem(__("X"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BonePosX;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        if (uiImMenuItem(__("Y"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BonePosY;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        if (uiImMenuItem(__("Z"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BonePosZ;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        if (uiImMenuItem(__("Roll"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BoneRotRoll;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        if (uiImMenuItem(__("Pitch"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BoneRotPitch;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        if (uiImMenuItem(__("Yaw"))) {
                            binding.sourceName = source.name;
                            binding.sourceType = SourceType.BoneRotYaw;
                            binding.createSourceDisplayName();
                            trackingFilter = null;
                        }
                        uiImEndMenu();
                    }
                } else {
                    if (uiImSelectable(nameValid ? source.cName : "###NoName", selected)) {
                        trackingFilter = null;
                        binding.sourceType = SourceType.Blendshape;
                        binding.sourceName = source.name;
                        binding.createSourceDisplayName();
                    }
                }
            }
            uiImEndComboBox();
        }

        if (hasTrackingSrc) {
            uiImCheckbox(__("Inverse"), binding.inverse);

            uiImLabel(_("Dampen"));
            uiImDrag(binding.dampenLevel, 0, 10);

            uiImLabel(_("Tracking In"));
            uiImPush(0);
                uiImIndent();
                    uiImProgress(binding.inVal);
                    switch(binding.sourceType) {
                        case SourceType.Blendshape:
                            // TODO: Make all blendshapes in facetrack-d 0->1
                            uiImRange(binding.inRange.x, binding.inRange.y, -1, 1);
                            break;

                        case SourceType.BonePosX:
                        case SourceType.BonePosY:
                        case SourceType.BonePosZ:
                            uiImRange(binding.inRange.x, binding.inRange.y, -float.max, float.max);
                            break;

                        case SourceType.BoneRotPitch:
                        case SourceType.BoneRotRoll:
                        case SourceType.BoneRotYaw:
                            uiImRange(binding.inRange.x, binding.inRange.y, -180, 180);
                            break;
                            
                        default: assert(0);
                    }
                uiImUnindent();
            uiImPop();
            
            uiImLabel(_("Tracking Out"));
            uiImPush(1);
                uiImIndent();
                    uiImRange(binding.outRange.x, binding.outRange.y, -float.max, float.max);
                    uiImProgress(binding.outVal);
                uiImUnindent();
            uiImPop();
        }
    }

protected:

    override 
    void onUpdate() {
        auto item = insSceneSelectedSceneItem();
        if (item) {
            if (uiImButton(__("Refresh"))) {
                insScene.space.refresh();
                refresh(item.bindings);
            }

            uiImSameLine(0, 4);

            if (uiImButton(__("Save to File"))) {
                try {
                item.saveBindings();
                } catch (Exception ex) {
                    uiImDialog(__("Error"), ex.msg);
                }
            }

            foreach(i, ref TrackingBinding binding; item.bindings) {
                uiImPush(&binding);
                    if (uiImHeader(binding.name.toStringz, true)) {
                        settingsPopup(binding);

                        uiImIndent();
                            switch(binding.type) {

                                case BindingType.RatioBinding:
                                    ratioBinding(i, binding);
                                    break;

                                case BindingType.ExpressionBinding:
                                    exprBinding(i, binding);
                                    break;

                                // External bindings
                                default: 
                                    uiImLabel(_("No settings available."));
                                    break;
                            }
                        uiImUnindent();
                    }
                uiImPop();
            }
        } else uiImLabel(_("No puppet selected"));
    }

public:
    this() {
        super("Tracking", _("Tracking"), true);
    }
}

mixin inPanel!TrackingPanel;