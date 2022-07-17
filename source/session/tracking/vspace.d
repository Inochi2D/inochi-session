module session.tracking.vspace;
import session.tracking.sources;
import session.log;
import std.uni : toLower;
import std.string;

import inmath;
public import ft.data : Bone;

/**
    A virtual tracking space
*/
class VirtualSpace {
private:
    VirtualSpaceZone[] zones;
    size_t activeZone;

    IBindingSource[] allSources;
    string[] allBlendshapes;
    string[] allBones;
    void rebuildZoneList() {
        allSources.length = 0;
        allBlendshapes.length = 0;
        allBones.length = 0;

        foreach(ref zone; zones) {
            insLogInfo("Found zone %s", zone.name);
            allSources ~= zone.sources;
        }

        foreach(ref source; allSources) {
            source.update();
            import std.algorithm.searching : canFind;
            foreach(bskey; source.getBlendshapeKeys()) {
                if (!allBlendshapes.canFind(bskey)) {
                    allBlendshapes ~= bskey;
                }
            }

            foreach(bskey; source.getBoneKeys()) {
                if (!allBones.canFind(bskey)) {
                    allBones ~= bskey;
                }
            }
        }
    }

public:

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
    ref IBindingSource[] getAllSources() {
        return allSources;
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

    void refresh() {
        rebuildZoneList();
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
                source.update();
            }
        }

        // Update zones
        if (!currentZone.sources[0].isTrackingActive) {
            foreach(i, ref zone; zones) {
                if (zone.sources[0].isTrackingActive) {
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

    /**
        Zone name
    */
    string name;

    /**
        The sources this virtual space is getting data from
    */
    IBindingSource[] sources;

    /**
        Gets the tracking data for a specified blendshape name
    */
    float getBlendshapeFor(string name) {
        float sum = 0;
        float count = 0;
        foreach(source; sources) {
            if (name in source.getBlendshapes) {
                sum += source.getBlendshape(name);
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
        Bone sum;
        sum.position = sources[0].getBone(name).position;
        sum.rotation = sources[0].getBone(name).rotation;

        if (sources.length > 1) {
            float count = 1;
            foreach(source; sources[1..$]) {
                if (name in source.getBones) {
                    count += 1;

                    Bone b = source.getBone(name);
                    sum.position += b.position; 
                    sum.rotation = slerp(sum.rotation, b.rotation, 1f/(count+1));
                }
            }
            sum.position /= count;
        }
        return sum;
    }
}