module session.widgets.scene;
import inui.widgets;
import inui.app;
import inochi2d;

import std.stdio : writeln;
import std.file : exists;
import inui.core.msgbox;

/**
    The Inochi2D Scene
*/
class Scene : GLArea {
private:
    Puppet[] puppets;

protected:
    
    override
    void onGLInit() {
        inInit(() => cast(double)Application.thisApp.currentTime());
	    inGetCamera().scale = vec2(0.25);

        foreach(arg; Application.thisApp.args) {
            if (arg.exists) {
                puppets ~= inLoadPuppet(arg);
            }
        }
    }
    
    override
    void onDrawGL(float delta) {
        
        inUpdate();
        inBeginScene();
        foreach(puppet; puppets) {
            puppet.update();
            puppet.draw();
        }
        inEndScene();
        inPostProcessScene();

        int w, h;
		inGetViewport(w, h);

        glBindFramebuffer(GL_FRAMEBUFFER, this.mainFBO);

        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
		inDrawScene(vec4(0, 0, w, h));
    }

    override
    void onSizeChanged(vec2 oldSize, vec2 newSize) {
        super.onSizeChanged(oldSize, newSize);
        inSetViewport(cast(uint)newSize.x, cast(uint)newSize.y);
    }

public:

    this() { 
        super();
        this.styleClass = "scene";
    }
}
