pub const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("epoxy/glx.h");
    @cInclude("GLFW/glfw3.h");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cDefine("CIMGUI_USE_GLFW", "");
    @cDefine("CIMGUI_USE_OPENGL3", "");
    @cDefine("igGetIO", "igGetIO_Nil");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
    @cInclude("stb_image.h");
});
