return {begin=function(BUS)
    local ENV = BUS.ENV
    local log = BUS.log

    log("[ Loading plugin api modules.. ]",log.info)
    ENV.c3d.plugin   = require("modules.plugin")  (BUS,ENV)
    ENV.c3d.registry = require("modules.registry")(BUS)
    log("[ Loading plugin api objects.. ]",log.info)
    BUS.object.registry_entry = require("core.objects.registry_entry").add(BUS)
    BUS.object.plugin         = require("core.objects.plugin")        .add(BUS)
    log("",log.info)

    log("[ Loading internal objects.. ]",log.info)
    ENV.c3d.plugin.load(require("core.objects.palette")         .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.texture")         .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.scene_object")    .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.generic_shape")   .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.camera")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.imported_model")  .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.vector")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.animated_texture").add(BUS))
    ENV.c3d.plugin.load(require("core.objects.sprite_sheet")    .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.raw_mesh")        .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.material")        .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.layout")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.pipeline")        .add(BUS))
    BUS.plugin_internal.register_objects       ()
    BUS.plugin_internal.load_registered_objects()

    log("[ Loading internal modules.. ]",log.info)
    ENV.c3d.plugin.load(require("modules.timer")      (BUS))
    ENV.c3d.plugin.load(require("modules.event")      (BUS))
    ENV.c3d.plugin.load(require("modules.graphics")   (BUS))
    ENV.c3d.plugin.load(require("modules.keyboard")   (BUS))
    ENV.c3d.plugin.load(require("modules.mouse")      (BUS))
    ENV.c3d.plugin.load(require("modules.thread")     (BUS))
    ENV.c3d.plugin.load(require("modules.sys")        (BUS))
    ENV.c3d.plugin.load(require("modules.scene")      (BUS))
    ENV.c3d.plugin.load(require("modules.perspective")(BUS))
    ENV.c3d.plugin.load(require("modules.geometry")   (BUS))
    ENV.c3d.plugin.load(require("modules.shader")     (BUS))
    ENV.c3d.plugin.load(require("modules.camera")     (BUS))
    ENV.c3d.plugin.load(require("modules.pipeline")   (BUS))
    ENV.c3d.plugin.load(require("modules.vector")     (BUS))
    ENV.c3d.plugin.load(require("modules.interact")   (BUS))
    ENV.c3d.plugin.load(require("modules.mesh")       (BUS))
    ENV.c3d.plugin.load(require("modules.log")        (BUS))
    ENV.c3d.plugin.load(require("modules.palette")    (BUS))
    ENV.c3d.plugin.load(require("modules.model")      (BUS))
    BUS.plugin_internal.register_modules       ()
    BUS.plugin_internal.load_registered_modules()

    ENV.c3d.plugin.load(require("core.codegen.macros.core.component_argument")(BUS))

    ENV.c3d.plugin.load(require("core.pipeline.macros.test")                  (BUS))
    BUS.plugin_internal.register_macros()
    BUS.plugin_internal.load_registered_macros()

    ENV.c3d.plugin.load("core.pipeline.components.__root__",ENV.c3d.plugin.sign{from_file=true,component_prefix="__c3d_register"})
    BUS.plugin_internal.register_components()
    BUS.plugin_internal.load_registered_components()

    require("modules.c3d")(BUS,ENV)
end}