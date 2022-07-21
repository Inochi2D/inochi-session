module session.panels.tracking;
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

    void ratioBinding(size_t i, ref TrackingBinding binding) {
        bool hasTrackingSrc = binding.sourceName.length > 0;

        uiImPush(&binding);
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
                    if (source.isBone) {
                        if (uiImBeginMenu(source.cName)) {
                            if (uiImMenuItem(__("X"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BonePosX;
                                binding.createSourceDisplayName();
                            }
                            if (uiImMenuItem(__("Y"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BonePosY;
                                binding.createSourceDisplayName();
                            }
                            if (uiImMenuItem(__("Z"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BonePosZ;
                                binding.createSourceDisplayName();
                            }
                            if (uiImMenuItem(__("Roll"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BoneRotRoll;
                                binding.createSourceDisplayName();
                            }
                            if (uiImMenuItem(__("Pitch"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BoneRotPitch;
                                binding.createSourceDisplayName();
                            }
                            if (uiImMenuItem(__("Yaw"))) {
                                binding.sourceName = source.name;
                                binding.sourceType = SourceType.BoneRotYaw;
                                binding.createSourceDisplayName();
                            }
                            uiImEndMenu();
                        }
                    } else {
                        if (uiImSelectable(source.cName, selected)) {
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
        uiImPop();
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
                item.saveBindings();
            }

            foreach(i, ref TrackingBinding binding; item.bindings) {
                if (!uiImHeader(binding.name.toStringz, true)) continue;

                uiImIndent();
                    switch(binding.type) {

                        case BindingType.RatioBinding:
                            ratioBinding(i, binding);
                            break;

                        case BindingType.ExpressionBinding:
                        
                            break;

                        // External bindings
                        default: 
                            uiImLabel(_("No settings available."));
                            break;
                    }
                uiImUnindent();
            }
        } else uiImLabel(_("No puppet selected"));
    }

public:
    this() {
        super("Tracking", _("Tracking"), true);
    }
}

mixin inPanel!TrackingPanel;