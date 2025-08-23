module app;
import session;
import inui;

void main(string[] args) {
    AppInfo info = {
        name: "Inochi Session",
        author: "Inochi2D Project",
        id: "com.inochi2d.inochi-session",
        version_: import("version.txt"),
    };

    Application app = new Application(info);
    app.stylesheet = StyleSheet.parse(import("style.css"));
    
    Window window = (new Window(app.appInfo.name, 640, 480))
        .resizable(true)
        .vibrancy(SystemVibrancy.vivid);
    
    window.view.addWidget(new Scene());
    app.run(window, args);
}