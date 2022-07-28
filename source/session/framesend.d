module session.framesend;
import session.log;
import inochi2d;
import bindbc.opengl;
import i18n;

version(Windows) {
    import bindbc.spout2;
    import bindbc.spout2.types;
}

private {
    bool loadSuccessful;
    version(Windows) {
        SPOUTHANDLE spHandle;
    }
}

/**
    Initializes the frame sender system
*/
void insInitFrameSending() {
    version(Windows) {
        auto loadMode = loadSpout2();
        loadSuccessful = loadMode == Spout2Support.spout2;
        if (loadSuccessful) {
            spHandle = spGetSpout();
            spSetSenderName(spHandle, "Inochi Session");
            spSetSenderFormat(spHandle, 28); // DXGI 8-bit RGBA
        }
    }

    if (!loadSuccessful) insLogErr(_("Could not start texture sharing, it will be disabled. Is the library missing?"));
    else insLogInfo(_("Frame-sending started successfully!"));
}

/**
    Cleans up the frame sender system
*/
void insCleanupFrameSending() {
    if (loadSuccessful) {
        version(Windows) {
            spReleaseSender(spHandle, 0);
            unloadSpout2();
        }
    }
}

/**
    Sends a frame
*/
void insSendFrame() {
    if (loadSuccessful) {
        int w, h;
        inGetViewport(w, h);

        version(Windows) {
            spSendTexture(spHandle, inGetRenderImage(), GL_TEXTURE_2D, w, h, true, inGetFramebuffer());
        }
    }
}

/**
    Gets whether low-overhead texture sharing is enabled.
*/
bool insCanSendFrames() {
    return loadSuccessful;
}