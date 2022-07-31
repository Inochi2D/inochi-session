/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.tracking.vspace;
import session.log;
import std.uni : toLower;
import std.string;

import inmath;
public import ft.data : Bone;
public import ft;
import inui.core.settings;
import inui.core.utils;
import fghj;


void insSaveVSpace(ref VirtualSpace space) {
    inSettingsSet("space", space);
    inSettingsSave();
}

VirtualSpace insLoadVSpace() {
    if (!inSettingsCanGet("space")) {
        insLogInfo("No VirtualSpace found, creating a new one...");
        return new VirtualSpace();
    }
    return inSettingsGet!VirtualSpace("space", new VirtualSpace());
}

/**
    A virtual tracking space
*/
class VirtualSpace {
private:
    VirtualSpaceZone[] zones;
    size_t activeZone;
    bool hasAnyFocus_ = true;

    Adaptor[] allSources;
    string[] allBlendshapes;
    string[] allBones;
    void rebuildZoneList() {
        allSources.length = 0;
        allBlendshapes.length = 0;
        allBones.length = 0;

        foreach(ref zone; zones) {
            insLogInfo("Found zone %s", zone.name);
            if (zone.sources && zone.sources.length > 0) allSources ~= zone.sources;
        }

        foreach(ref source; allSources) {
            if (!source) continue;

            source.poll();
            import std.algorithm.searching : canFind;
            foreach(bskey; source.getBlendshapes().keys) {
                if (!allBlendshapes.canFind(bskey)) {
                    allBlendshapes ~= bskey;
                }
            }

            foreach(bskey; source.getBones().keys) {
                if (!allBones.canFind(bskey)) {
                    allBones ~= bskey;
                }
            }
        }
    }

public:
    this() { }

    void serialize(S)(ref S serializer) {
        insLogInfo("Saving Virtual Space...");
        auto state = serializer.objectBegin;
            serializer.putKey("zones");
            auto arrstate = serializer.arrayBegin();
                foreach(ref zone; zones) {
                    insLogInfo("Saving Zone %s...", zone.name);
                    serializer.elemBegin();
                    serializer.serializeValue(zone);
                }
            serializer.arrayEnd(arrstate);
        serializer.objectEnd(state);
    }

    SerdeException deserializeFromFghj(Fghj data) {
        if (!data["zones"].isEmpty) {
            foreach(child; data["zones"].byElement) {
                VirtualSpaceZone zone = new VirtualSpaceZone();
                child.deserializeValue(zone);

                zones ~= zone;
            }
        }
        rebuildZoneList();
        return null;
    }

    /**
        Gets the current zone tracking is happening in
    */
    VirtualSpaceZone currentZone() {
        return activeZone < zones.length ? zones[activeZone] : null;
    }

    /**
        Returns a duplicated list of the zones
    */
    VirtualSpaceZone[] getZones() {
        return zones.dup;
    }

    /**
        Returns a list of the active blendshapes
    */
    string[] getAllBlendshapeNames() {
        return allBlendshapes;
    }

    /**
        Returns a list of the active blendshapes
    */
    string[] getAllBoneNames() {
        return allBones;
    }

    /**
        Returns a list of the sources
    */
    ref Adaptor[] getAllSources() {
        return allSources;
    }

    bool hasAnyFocus() {
        return hasAnyFocus_;
    }

    /**
        Adds a zone
    */
    void addZone(VirtualSpaceZone zone) {
        zones ~= zone;
        rebuildZoneList();
    }

    /**
        Removes zone
    */
    void removeZone(VirtualSpaceZone zone) {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;
        auto idx = zones.countUntil(zone);
        if (idx >= 0) {
            zones = zones.remove(idx);
        }
        rebuildZoneList();
    }

    /**
        Removes zone
    */
    void removeZoneAt(size_t idx) {
        import std.algorithm.mutation : remove;
        if (idx >= 0 && idx < zones.length) {
            zones = zones.remove(idx);
        }
        rebuildZoneList();
    }

    void refresh() {
        rebuildZoneList();
    }

    bool isCurrentZoneActive() {
        return currentZone.sources.length > 0 && currentZone.sources[0] && currentZone.sources[0].isReceivingData;
    }

    /**
        Updates the virtual space
    */
    void update() {

        // There's no zones defined with trackers
        if (zones.length == 0) return;

        if (currentZone is null) {
            activeZone = 0;
        }

        // Update all sources
        foreach(ref zone; zones) {
            foreach(ref source; zone.sources) {
                if (source) source.poll();
            }
        }

        hasAnyFocus_ = isCurrentZoneActive();
        if (!hasAnyFocus_) {
            foreach(i, ref zone; zones) {
                if (zone.sources.length == 0) continue;

                if (zone.sources[0] && zone.sources[0].isReceivingData) {
                    activeZone = i;
                }
            }
        }
    }
}

/**
    A zone within the virtual space
*/
class VirtualSpaceZone {
private:

public:
    this() { }

    this(string name) {
        this.name = name;
    }

    
    void serialize(S)(ref S serializer) {
        auto state = serializer.objectBegin;
            serializer.putKey("name");
            serializer.putValue(name);
            serializer.putKey("sources");
            auto arrstate = serializer.arrayBegin();
                foreach(ref Adaptor source; sources) {
                    if (!source) continue;

                    serializer.elemBegin();

                    auto sstate = serializer.objectBegin;
                        serializer.putKey("type");
                        serializer.putValue(source.getAdaptorName());
                        if (source.getOptions !is null) {
                            serializer.putKey("options");
                            serializer.serializeValue(source.getOptions());
                        }
                    serializer.objectEnd(sstate);
                }
            serializer.arrayEnd(arrstate);
        serializer.objectEnd(state);
    }
    
    SerdeException deserializeFromFghj(Fghj data) {
        data["name"].deserializeValue(name);
        if (!data["sources"].isEmpty) {
            foreach(child; data["sources"].byElement) {
                string type;
                string[string] xdata;
                child["type"].deserializeValue(type);
                try {
                    Adaptor adaptor;
                    if (!child["options"].isEmpty) {
                        child["options"].deserializeValue(xdata);

                        // NOTE: inochi-session should ALWAYS be the appName.
                        xdata["appName"] = "inochi-session";
                        if (type == "VMC Receiver") xdata["address"] = "0.0.0.0";
                        adaptor = ftCreateAdaptor(type);
                        adaptor.setOptions(xdata);

                        if (adaptor) sources ~= adaptor;
                        adaptor.start();
                    } else {
                        
                        // NOTE: inochi-session should ALWAYS be the appName.
                        xdata["appName"] = "inochi-session";
                        if (type == "VMC Receiver") xdata["address"] = "0.0.0.0";
                        adaptor = ftCreateAdaptor(type);
                        adaptor.setOptions(xdata);
                    
                        if (adaptor) sources ~= adaptor;
                    }
                } catch (Exception ex) {
                    insLogErr("%s: %s", name, ex.msg);
                }
            }
        }
        return null;
    }

    /**
        Zone name
    */
    string name;

    /**
        The sources this virtual space is getting data from
    */
    Adaptor[] sources;

    /**
        Gets the tracking data for a specified blendshape name
    */
    float getBlendshapeFor(string name) {
        if (sources.length == 0) return 0;

        float sum = 0;
        float count = 0;
        foreach(ref source; sources) {
            if (!source) continue;
            
            if (name in source.getBlendshapes) {
                sum += source.getBlendshapes()[name];
                count += 1;
            }
        }

        if (sum == 0 || count == 0) return 0;
        return sum/count;
    }

    /**
        Gets the tracking data for a specified bone name
    */
    Bone getBoneFor(string name) {
        Bone sum = Bone(vec3(0), quat.identity);

        // Edgecases that may cause crashes, avoid them
        if (sources.length == 0 || !sources[0]) return sum;
        if (name !in sources[0].getBones) return sum;
        
        sum.position = sources[0].getBones()[name].position;
        sum.rotation = sources[0].getBones()[name].rotation;

        if (sources.length > 1) {
            float count = 1;
            foreach(ref source; sources[1..$]) {
                if (name in source.getBones) {
                    count += 1;

                    Bone b = source.getBones()[name];
                    sum.position += b.position; 
                    sum.rotation = slerp(sum.rotation, b.rotation, 1f/(count+1));
                }
            }
            sum.position /= count;
        }
        return sum;
    }
}