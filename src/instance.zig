const std = @import("std");
const Io = std.Io;

const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const ChainedStructOut = _chained_struct.ChainedStructOut;
const SType = _chained_struct.SType;

const _adapter = @import("adapter.zig");
const Adapter = _adapter.Adapter;
const RequestAdapterOptions = _adapter.RequestAdapterOptions;
const RequestAdapterCallbackInfo = _adapter.RequestAdapterCallbackInfo;
const RequestAdapterCallback = _adapter.RequestAdapterCallback;
const RequestAdapterStatus = _adapter.RequestAdapterStatus;
const RequestAdapterResponse = _adapter.RequestAdapterResponse;
const BackendType = _adapter.BackendType;

const _surface = @import("surface.zig");
const Surface = _surface.Surface;
const SurfaceDescriptor = _surface.SurfaceDescriptor;

const _misc = @import("misc.zig");
const WGPUFlags = _misc.WGPUFlags;
const WGPUBool = _misc.WGPUBool;
const StringView = _misc.StringView;
const Status = _misc.Status;

const _async = @import("async.zig");
const Future = _async.Future;
const WaitStatus = _async.WaitStatus;
const FutureWaitInfo = _async.FutureWaitInfo;

pub const InstanceBackend = WGPUFlags;
pub const InstanceBackends = struct {
    pub const all            = @as(InstanceBackend, 0x00000000);
    pub const vulkan         = @as(InstanceBackend, 0x00000001);
    pub const gl             = @as(InstanceBackend, 0x00000002);
    pub const metal          = @as(InstanceBackend, 0x00000004);
    pub const dx12           = @as(InstanceBackend, 0x00000008);

    /// Deprecated
    pub const dx11           = @as(InstanceBackend, 0x00000010);

    pub const browser_webgpu = @as(InstanceBackend, 0x00000020);
    pub const primary        = vulkan | metal | dx12 | browser_webgpu;
    pub const secondary      = gl;
};

pub const InstanceFlag = WGPUFlags;
pub const InstanceFlags = struct {
    pub const empty              = @as(InstanceFlag, 0x00000000);
    pub const debug              = @as(InstanceFlag, 1 << 0);
    pub const validation         = @as(InstanceFlag, 1 << 1);
    pub const discard_hal_labels = @as(InstanceFlag, 1 << 2);
    pub const allow_underlying_non_compliant_adapter = @as(InstanceFlag, 1 << 3);
    pub const gpu_based_validation = @as(InstanceFlag, 1 << 4);
    pub const validation_indirect_call = @as(InstanceFlag, 1 << 5);
    pub const automatic_timestamp_normalization = @as(InstanceFlag, 1 << 6);
    pub const default = @as(InstanceFlag, 1 << 24);
    pub const debugging = @as(InstanceFlag, 1 << 25);
    pub const advanced_debugging = @as(InstanceFlag, 1 << 26);
    pub const with_env = @as(InstanceFlag, 1 << 27);
};

pub const Dx12Compiler = enum(u32) {
    @"undefined" = 0x00000000,
    fxc          = 0x00000001,
    dxc          = 0x00000002,
};

pub const Dx12SwapchainKind = enum(u32) {
    undefined        = 0x00000000,
    dxgi_from_hwnd   = 0x00000001,
    dxgi_from_visual = 0x00000002,
};

pub const Gles3MinorVersion = enum(u32) {
    automatic  = 0x00000000,
    version_0  = 0x00000001,
    version_1  = 0x00000002,
    version_2  = 0x00000003,
};

pub const DxcMaxShaderModel = enum(u32) {
    dxc_max_shader_model_v6_0 = 0x00000000,
    dxc_max_shader_model_v6_1 = 0x00000001,
    dxc_max_shader_model_v6_2 = 0x00000002,
    dxc_max_shader_model_v6_3 = 0x00000003,
    dxc_max_shader_model_v6_4 = 0x00000004,
    dxc_max_shader_model_v6_5 = 0x00000005,
    dxc_max_shader_model_v6_6 = 0x00000006,
    dxc_max_shader_model_v6_7 = 0x00000007,
};

pub const GLFenceBehaviour = enum(u32) {
    gl_fence_behaviour_normal      = 0x00000000,
    gl_fence_behaviour_auto_finish = 0x00000001,
};

pub const DisplayHandleType = enum(u32) {
    none    = 0x00000000,
    xlib    = 0x00000001,
    xcb     = 0x00000002,
    wayland = 0x00000003,
};

pub const XlibDisplayHandle = extern struct {
    /// Pointer to the X11 @c Display
    display: *anyopaque,
    /// X11 screen number
    screen: i32,
};

pub const XcbDisplayHandle = extern struct {
    /// Pointer to the XCB connection
    connection: *anyopaque,
    /// X11 screen number
    screen: i32,
};

pub const WaylandDisplayHandle = extern struct {
    /// Pointer to the Wayland display
    display: *anyopaque
};

pub const DisplayHandle = extern struct {
    @"type": DisplayHandleType,
    data: extern union { 
        xlib: XlibDisplayHandle,
        xcb: XcbDisplayHandle,
        wayland: WaylandDisplayHandle,
    }
};

pub const InstanceExtras = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.instance_extras,
    },
    backends: InstanceBackend,
    flags: InstanceFlag,
    dx12_shader_compiler: Dx12Compiler,
    gles3_minor_version: Gles3MinorVersion,
    gl_fence_behavior: GLFenceBehaviour,
    dxc_path: StringView = StringView {},
    dxc_max_shader_model: DxcMaxShaderModel,
    dx12_presenetation_system: Dx12SwapchainKind,

    budget_for_device_creation: ?*const u8,
    budget_for_device_loss: ?*const u8,

    display_handle: DisplayHandle,
};

pub const InstanceLimits = extern struct {
    // This struct chain is used as mutable in some places and immutable in others.
    next_in_chain: ?*ChainedStructOut = null,

    // The maximum number FutureWaitInfo supported in a call to ::wgpuInstanceWaitAny with `timeoutNS > 0`.
    timed_wait_any_max_count: usize,
};

pub const InstanceDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,

    required_feature_count: usize,
    required_features: [*]const InstanceFeatureName,
    required_limits: ?*const InstanceLimits,

    pub inline fn withNativeExtras(self: InstanceDescriptor, extras: *InstanceExtras) InstanceDescriptor {
        var id = self;
        id.next_in_chain = @ptrCast(extras);
        return id;
    }
};

extern fn wgpuSupportedInstanceFeaturesFreeMembers(supported_instance_features: SupportedInstanceFeatures) void;

pub const SupportedInstanceFeatures = extern struct {
    feature_count: usize,
    features: [*]const InstanceFeatureName,

    pub inline fn freeMembers(self: SupportedInstanceFeatures) void {
        wgpuSupportedInstanceFeaturesFreeMembers(self);
    }
};

pub const WGSLLanguageFeatureName = enum(u32) {
    readonly_and_readwrite_storage_textures = 0x00000001,
    packed4x8_integer_dot_product           = 0x00000002,
    unrestricted_pointer_parameters         = 0x00000003,
    pointer_composite_access                = 0x00000004,
    uniform_buffer_standard_layout          = 0x00000005,
    subgroup_id                             = 0x00000006,
    texture_and_sampler_let                 = 0x00000007,
    subgroup_uniformity                     = 0x00000008,
    texture_formats_tier_1                  = 0x00000009,
    linear_indexing                         = 0x0000000A,
};

pub const InstanceFeatureName = enum(u32) {
    timed_wait_any = 0x00000001,
    shader_source_spirv = 0x00000002,
    multiple_devices_per_adapter = 0x00000003,
};

pub const SupportedWGSLLanguageFeaturesProcs = struct {
    pub const FreeMembers = *const fn(SupportedWGSLLanguageFeatures) callconv(.c) void;
};

extern fn wgpuSupportedWGSLLanguageFeaturesFreeMembers(supported_wgsl_language_features: SupportedWGSLLanguageFeatures) void;

pub const SupportedWGSLLanguageFeatures = extern struct {
    feature_count: usize,
    features: [*]const WGSLLanguageFeatureName,

    // Unimplemented as of wgpu-native v25.0.2.1,
    // see https://github.com/gfx-rs/wgpu-native/blob/d8238888998db26ceab41942f269da0fa32b890c/src/unimplemented.rs#L193
    // pub inline fn freeMembers(self: SupportedWGSLLanguageFeatures) void {
    //     wgpuSupportedWGSLLanguageFeaturesFreeMembers(self);
    // }
};

pub const InstanceProcs = struct {
    pub const CreateInstance = *const fn(?*const InstanceDescriptor) callconv(.c) ?*Instance;
    // TODO: Check if this is still valid or renamed
    pub const GetCapabilities = *const fn(*InstanceLimits) callconv(.c) Status;

    pub const CreateSurface = *const fn(*Instance, *const SurfaceDescriptor) callconv(.c) ?*Surface;
    pub const GetWGSLLanguageFeatures = *const fn(*Instance, *SupportedWGSLLanguageFeatures) callconv(.c) Status;
    pub const HasWGSLLanguageFeature = *const fn(*Instance, WGSLLanguageFeatureName) callconv(.c) WGPUBool;
    pub const ProcessEvents = *const fn(*Instance) callconv(.c) void;
    pub const RequestAdapter = *const fn(*Instance, ?*const RequestAdapterOptions, RequestAdapterCallbackInfo) callconv(.c) Future;
    pub const WaitAny = *const fn(*Instance, usize, ?[*] FutureWaitInfo, u64) callconv(.c) WaitStatus;
    pub const InstanceAddRef = *const fn(*Instance) callconv(.c) void;
    pub const InstanceRelease = *const fn(*Instance) callconv(.c) void;

    // wgpu-native procs?
    // pub const GenerateReport = *const fn(*Instance, *GlobalReport) callconv(.c) void;
    // pub const EnumerateAdapters = *const fn(*Instance, ?*const EnumerateAdapterOptions, ?[*]Adapter) callconv(.c) usize;
};

extern fn wgpuGetInstanceLimits(capabilities: *InstanceLimits) Status;

extern fn wgpuCreateInstance(descriptor: ?*const InstanceDescriptor) ?*Instance;
extern fn wgpuGetInstanceFeatures(features: *SupportedInstanceFeatures) void;
extern fn wgpuHasInstanceFeature(features: InstanceFeatureName) WGPUBool;

extern fn wgpuInstanceCreateSurface(instance: *Instance, descriptor: *const SurfaceDescriptor) ?*Surface;
extern fn wgpuInstanceGetWGSLLanguageFeatures(instance: *Instance, features: *SupportedWGSLLanguageFeatures) Status;
extern fn wgpuInstanceHasWGSLLanguageFeature(instance: *Instance, feature: WGSLLanguageFeatureName) WGPUBool;
extern fn wgpuInstanceProcessEvents(instance: *Instance) void;
extern fn wgpuInstanceRequestAdapter(instance: *Instance, options: ?*const RequestAdapterOptions, callback_info: RequestAdapterCallbackInfo) Future;
extern fn wgpuInstanceWaitAny(instance: *Instance, future_count: usize, futures: ?[*] FutureWaitInfo, timeout_ns: u64) WaitStatus;
extern fn wgpuInstanceAddRef(instance: *Instance) void;
extern fn wgpuInstanceRelease(instance: *Instance) void;

pub const RegistryReport = extern struct {
    num_allocated: usize,
    num_kept_from_user: usize,
    num_released_from_user: usize,
    element_size: usize,
};

pub const HubReport = extern struct {
    adapters: RegistryReport,
    devices: RegistryReport,
    queues: RegistryReport,
    pipeline_layouts: RegistryReport,
    shader_modules: RegistryReport,
    bind_group_layouts: RegistryReport,
    bind_groups: RegistryReport,
    command_buffers: RegistryReport,
    render_bundles: RegistryReport,
    render_pipelines: RegistryReport,
    compute_pipelines: RegistryReport,
    pipeline_caches: RegistryReport,
    query_sets: RegistryReport,
    buffers: RegistryReport,
    textures: RegistryReport,
    texture_views: RegistryReport,
    samplers: RegistryReport,
};

pub const GlobalReport = extern struct {
    surfaces: RegistryReport,
    hub: HubReport,
};

pub const EnumerateAdapterOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    backends: InstanceBackend,
};

// wgpu-native
extern fn wgpuGenerateReport(instance: *Instance, report: *GlobalReport) void;
extern fn wgpuInstanceEnumerateAdapters(instance: *Instance, options: ?*EnumerateAdapterOptions, adapters: ?[*]*Adapter) usize;

pub const Instance = opaque {
    // This is a global function, but it creates an instance so I put it here.
    pub inline fn create(descriptor: ?*const InstanceDescriptor) ?*Instance {
        return wgpuCreateInstance(descriptor);
    }

    pub inline fn getFeatures(features: *SupportedInstanceFeatures) void {
        wgpuGetInstanceFeatures(features);
    }
    pub inline fn hasFeature(feature: InstanceFeatureName) bool {
        return @bitCast(wgpuHasInstanceFeature(feature));
    }

    // This is also a global function, but I think it would make sense being a member of Instance;
    // You'd use it like `const status = Instance.getCapabilities(&capabilities);`
    pub inline fn getLimits(limits: *InstanceLimits) Status {
        return wgpuGetInstanceLimits(limits);
    }

    pub inline fn createSurface(self: *Instance, descriptor: *const SurfaceDescriptor) ?*Surface {
        return wgpuInstanceCreateSurface(self, descriptor);
    }

    // Unimplemented as of wgpu-native v25.0.2.1,
    // see https://github.com/gfx-rs/wgpu-native/blob/d8238888998db26ceab41942f269da0fa32b890c/src/unimplemented.rs#L100
    // pub inline fn getWGSLLanguageFeatures(self: *Instance, features: *SupportedWGSLLanguageFeatures) Status {
    //     return wgpuInstanceGetWGSLLanguageFeatures(self, features);
    // }

    // Unimplemented as of wgpu-native v25.0.2.1,
    // see https://github.com/gfx-rs/wgpu-native/blob/d8238888998db26ceab41942f269da0fa32b890c/src/unimplemented.rs#L108
    // pub inline fn hasWGSLLanguageFeature(self: *Instance, feature: WGSLLanguageFeatureName) bool {
    //     return wgpuInstanceHasWGSLLanguageFeature(self, feature) != 0;
    // }

    // Processes asynchronous events on this Instance, calling any callbacks for asynchronous operations created with `CallbackMode.allow_process_events`.
    pub inline fn processEvents(self: *Instance) void {
        wgpuInstanceProcessEvents(self);
    }

    fn defaultAdapterCallback(status: RequestAdapterStatus, adapter: ?*Adapter, message: StringView, userdata1: ?*anyopaque, userdata2: ?*anyopaque) callconv(.c) void {
        const ud_response: *RequestAdapterResponse = @ptrCast(@alignCast(userdata1));
        ud_response.* = RequestAdapterResponse {
            .status = status,
            .message = message.toSlice(),
            .adapter = adapter,
        };

        const completed: *bool = @ptrCast(@alignCast(userdata2));
        completed.* = true;
    }

    // This is a synchronous wrapper that handles asynchronous (callback) logic.
    // It uses polling to see when the request has been fulfilled, so needs a polling interval parameter.
    pub fn requestAdapterSync(self: *Instance, options: ?*const RequestAdapterOptions, io: Io, duration: Io.Duration) RequestAdapterResponse {
        var response: RequestAdapterResponse = undefined;
        var completed = false;
        const callback_info = RequestAdapterCallbackInfo {
            .callback = defaultAdapterCallback,
            .userdata1 = @ptrCast(&response),
            .userdata2 = @ptrCast(&completed),
        };
        const adapter_future = wgpuInstanceRequestAdapter(self, options, callback_info);

        // TODO: Revisit once Instance.waitAny() is implemented in wgpu-native,
        //       it takes in futures and returns when one of them completes.
        _ = adapter_future;
        self.processEvents();
        while (!completed) {
            io.sleep(duration, .cpu_thread) catch {};
            self.processEvents();
        }

        return response;
    }

    pub inline fn requestAdapter(self: *Instance, options: ?*const RequestAdapterOptions, callback_info: RequestAdapterCallbackInfo) Future {
        return wgpuInstanceRequestAdapter(self, options, callback_info);
    }

    // Unimplemented as of wgpu-native v25.0.2.1,
    // see https://github.com/gfx-rs/wgpu-native/blob/d8238888998db26ceab41942f269da0fa32b890c/src/unimplemented.rs#L224
    // Wait for at least one Future in `futures` to complete, and call callbacks of the respective completed asynchronous operations.
    // pub inline fn waitAny(self: *Instance, future_count: usize, futures: ?[*] FutureWaitInfo, timeout_ns: u64) WaitStatus {
    //     return wgpuInstanceWaitAny(self, future_count, futures, timeout_ns);
    // }

    pub inline fn addRef(self: *Instance) void {
        wgpuInstanceAddRef(self);
    }


    pub inline fn release(self: *Instance) void {
        wgpuInstanceRelease(self);
    }

    // wgpu-native
    pub inline fn generateReport(self: *Instance, report: *GlobalReport) void {
        wgpuGenerateReport(self, report);
    }
    pub inline fn enumerateAdapters(self: *Instance, options: ?*EnumerateAdapterOptions, adapters: ?[*]*Adapter) usize {
        return wgpuInstanceEnumerateAdapters(self, options, adapters);
    }
};

test "can create instance (and release it afterwards)" {
    const testing = @import("std").testing;

    const instance = Instance.create(null);
    try testing.expect(instance != null);
    instance.?.release();
}

test "can request adapter" {
    const testing = @import("std").testing;

    const instance = Instance.create(null);
    const response = instance.?.requestAdapterSync(null, .fromMilliseconds(200));
    const adapter: ?*Adapter = switch(response.status) {
        .success => response.adapter,
        else => null,
    };
    try testing.expect(adapter != null);
}
