// Hydra KMDF PCIe driver stub (Windows)
// This is a non-building placeholder for bring-up. Drop into a KMDF project
// and wire the INF/VCXPROJ as needed.

#ifdef _WIN32
#include <ntddk.h>
#include <wdf.h>

#define HYDRA_VENDOR_ID_DEFAULT 0x1BAD
#define HYDRA_DEVICE_ID_DEFAULT 0x2024

typedef struct _HYDRA_DEVICE_CONTEXT {
    WDFDEVICE WdfDevice;
    PUCHAR    Bar0;
    ULONG     Bar0Length;
    PUCHAR    Bar1;
    ULONG     Bar1Length;
} HYDRA_DEVICE_CONTEXT, *PHYDRA_DEVICE_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(HYDRA_DEVICE_CONTEXT, HydraGetDeviceContext);

DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD HydraEvtDeviceAdd;
EVT_WDF_DEVICE_PREPARE_HARDWARE HydraEvtPrepareHardware;
EVT_WDF_DEVICE_RELEASE_HARDWARE HydraEvtReleaseHardware;

NTSTATUS
DriverEntry(_In_ PDRIVER_OBJECT DriverObject, _In_ PUNICODE_STRING RegistryPath)
{
    WDF_DRIVER_CONFIG config;
    WDF_DRIVER_CONFIG_INIT(&config, HydraEvtDeviceAdd);
    return WdfDriverCreate(DriverObject, RegistryPath, WDF_NO_OBJECT_ATTRIBUTES, &config, WDF_NO_HANDLE);
}

NTSTATUS
HydraEvtDeviceAdd(_In_ WDFDRIVER Driver, _Inout_ PWDFDEVICE_INIT DeviceInit)
{
    UNREFERENCED_PARAMETER(Driver);
    NTSTATUS status;
    WDFDEVICE device;
    WDF_OBJECT_ATTRIBUTES attributes;
    WDF_PNPPOWER_EVENT_CALLBACKS pnpCallbacks;

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, HYDRA_DEVICE_CONTEXT);
    WDF_PNPPOWER_EVENT_CALLBACKS_INIT(&pnpCallbacks);
    pnpCallbacks.EvtDevicePrepareHardware = HydraEvtPrepareHardware;
    pnpCallbacks.EvtDeviceReleaseHardware = HydraEvtReleaseHardware;
    WdfDeviceInitSetPnpPowerEventCallbacks(DeviceInit, &pnpCallbacks);

    status = WdfDeviceCreate(&DeviceInit, &attributes, &device);
    return status;
}

NTSTATUS
HydraEvtPrepareHardware(_In_ WDFDEVICE Device, _In_ WDFCMRESLIST ResourcesRaw, _In_ WDFCMRESLIST ResourcesTranslated)
{
    UNREFERENCED_PARAMETER(ResourcesRaw);
    PHYDRA_DEVICE_CONTEXT ctx = HydraGetDeviceContext(Device);
    ULONG resCount = WdfCmResourceListGetCount(ResourcesTranslated);
    for (ULONG i = 0; i < resCount; i++) {
        PCM_PARTIAL_RESOURCE_DESCRIPTOR res = WdfCmResourceListGetDescriptor(ResourcesTranslated, i);
        if (res->Type == CmResourceTypeMemory) {
            if (!ctx->Bar0) {
                ctx->Bar0 = (PUCHAR)MmMapIoSpace(res->u.Memory.Start, res->u.Memory.Length, MmNonCached);
                ctx->Bar0Length = res->u.Memory.Length;
            } else if (!ctx->Bar1) {
                ctx->Bar1 = (PUCHAR)MmMapIoSpace(res->u.Memory.Start, res->u.Memory.Length, MmNonCached);
                ctx->Bar1Length = res->u.Memory.Length;
            }
        }
    }
    return STATUS_SUCCESS;
}

NTSTATUS
HydraEvtReleaseHardware(_In_ WDFDEVICE Device, _In_ WDFCMRESLIST ResourcesTranslated)
{
    UNREFERENCED_PARAMETER(ResourcesTranslated);
    PHYDRA_DEVICE_CONTEXT ctx = HydraGetDeviceContext(Device);
    if (ctx->Bar0) {
        MmUnmapIoSpace(ctx->Bar0, ctx->Bar0Length);
        ctx->Bar0 = NULL;
    }
    if (ctx->Bar1) {
        MmUnmapIoSpace(ctx->Bar1, ctx->Bar1Length);
        ctx->Bar1 = NULL;
    }
    return STATUS_SUCCESS;
}

#endif /* _WIN32 */
