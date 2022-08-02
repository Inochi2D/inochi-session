/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.windows.spaceedit;
import session.scene;
import session.tracking.vspace;
import session.log;
import inui.widgets;
import inui.toolwindow;
import inmath;
import i18n;
import std.string;
import bindbc.imgui;
import ft;

import std.algorithm.mutation;

class SpaceEditor : ToolWindow {
private:
    VirtualSpaceZone editingZone;
    string newZoneName;

    void addZone() {
        if (newZoneName.length == 0) {
            uiImDialog(__("Error"), "Can't create a zone without a name!");
            return;
        }

        VirtualSpaceZone zone = new VirtualSpaceZone(newZoneName.dup);
        insScene.space.addZone(zone);

        newZoneName = null;
    }

    void switchZone(VirtualSpaceZone zone) {
        editingZone = zone;
        refreshOptionsList();
    }

    void refreshOptionsList() {
        options.clear();

        foreach(i; 0..editingZone.sources.length) {

            if (editingZone.sources[i] is null) continue;
            
            options[editingZone.sources[i]] = editingZone.sources[i].getOptions();
            options[editingZone.sources[i]]["appName"] = "inochi-session";
        }
    }

    string[string][Adaptor] options;

    void adaptorMenu(size_t idx) {
        uiImRightClickPopup("AdaptorPopup");

        if (uiImBeginPopup("AdaptorPopup")) {
            if (uiImMenuItem(__("Delete"))) {

                // stop source on delete
                if (editingZone.sources[idx]) editingZone.sources[idx].stop();
                editingZone.sources = editingZone.sources.remove(idx);
            }
            uiImEndPopup();
        }
    }

    void zoneMenu(size_t idx) {
        uiImRightClickPopup("AdaptorPopup");


        if (uiImBeginPopup("AdaptorPopup")) {
            if (uiImMenuItem(__("Delete"))) {
                
                // stop ALL sources on delete
                foreach(ref source; insScene.space.getZones()[idx].sources) {
                    if (source) source.stop();
                }
                insScene.space.removeZoneAt(idx);
            }
            uiImEndPopup();
        }
    }

    void adaptorSelect(size_t i, ref Adaptor source, const(char)* adaptorName) {
        if (uiImBeginComboBox("ADAPTOR_COMBO", adaptorName)) {
            if (uiImSelectable("VTubeStudio")) {
                if (source) source.stop();
                
                source = new VTSAdaptor();
                editingZone.sources[i] = source;
                refreshOptionsList();
            }
            if (uiImSelectable("VMC")) {
                if (source) source.stop();

                source = new VMCAdaptor();
                editingZone.sources[i] = source;
                refreshOptionsList();
            }
            if (uiImSelectable("OpenSeeFace")) {
                if (source) source.stop();

                source = new OSFAdaptor();
                editingZone.sources[i] = source;
                refreshOptionsList();
            }
            version (JML) {
                if (uiImSelectable("JINS MEME Logger")) {
                    if (source) source.stop();

                    source = new JMLAdaptor();
                    editingZone.sources[i] = source;
                    refreshOptionsList();
                }
            }
            uiImEndComboBox();
        }
    }

public:

    override
    void onUpdate() {
        vec2 avail = uiImAvailableSpace();
        float lhs = 196;
        float rhs = avail.x-lhs;

        if (uiImBeginChild("##LHS", vec2(lhs, -24), true)) {
            avail = uiImAvailableSpace();
            foreach(i, ref VirtualSpaceZone zone; insScene.space.getZones()) {
                uiImPush(cast(int)i);
                    if (uiImSelectable(zone.name.toStringz, zone == editingZone)) {
                        switchZone(zone);
                    }
                    zoneMenu(i);
                uiImPop();
            }

            uiImInputText("###ZONE_NAME", avail.x-24, newZoneName);
            uiImSameLine(0, 0);
            if (uiImButton(__(""), vec2(24, 24))) addZone();
        }
        uiImEndChild();

        uiImSameLine(0, 0);

        if (uiImBeginChild("##RHS", vec2(rhs, -24), true)) {
            if (editingZone is null) {
                uiImLabel(_("No zone selected for editing..."));
            } else {
                uiImPush(cast(int)editingZone.hashOf());
                    uiImInputText("###ZoneName", avail.x/2, editingZone.name);

                    uiImSeperator();
                    uiImNewLine();

                    uiImIndent();
                        foreach(i; 0..editingZone.sources.length) {
                            uiImPush(cast(int)i);
                                auto source = editingZone.sources[i];
                                const(char)* adaptorName = source is null ? __("Unset") : source.getAdaptorName().toStringz;

                                if (source is null) {
                                    if (uiImHeader(adaptorName, true)) {
                                        adaptorMenu(i);
                                        uiImIndent();
                                            adaptorSelect(i, source, adaptorName);
                                        uiImUnindent();
                                    } else {
                                        adaptorMenu(i);
                                    }
                                } else {
                                    if (uiImHeader(adaptorName, true)) {
                                        adaptorMenu(i);
                                        uiImIndent();
                                            avail = uiImAvailableSpace();
                                            
                                            adaptorSelect(i, source, adaptorName);

                                            igNewLine();

                                            foreach(option; source.getOptionNames()) {
                                                
                                                // Skip options which shouldn't be shown
                                                if (option == "appName") continue;
                                                if (option == "address") continue;

                                                if (option !in options[source]) options[source][option] = "";
                                                uiImLabel(option);
                                                uiImInputText(option, avail.x/2, options[source][option]);
                                            }

                                            if (uiImButton(__("Save Changes"))) {
                                                try {
                                                    source.setOptions(options[source]);
                                                    source.stop();
                                                    source.start();
                                                } catch(Exception ex) {
                                                    uiImDialog(__("Error"), ex.msg);
                                                }
                                            }

                                        uiImUnindent();
                                    } else {
                                        adaptorMenu(i);
                                    }
                                }
                            uiImPop();
                        }
                    uiImUnindent();

                    avail = uiImAvailableSpace();
                    if (uiImButton(__(""), vec2(avail.x, 24))) {
                        editingZone.sources.length++;
                        refreshOptionsList();
                    }
                uiImPop();
            }
        }
        uiImEndChild();

        uiImDummy(vec2(-64, 0));
        uiImSameLine(0, 0);
        if (uiImButton(__("Save"), vec2(64, 0))) {
            insSaveVSpace(insScene.space);
            this.close();
        }
    }

    this() {
        super(_("Virtual Space"));
    }
}
