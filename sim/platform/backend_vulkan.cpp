#include "backend_ops.h"

#if defined(HYDRA_ENABLE_VULKAN) && (defined(__has_include) ? __has_include(<vulkan/vulkan.h>) && __has_include(<SDL2/SDL_vulkan.h>) : 0)

#include <SDL2/SDL.h>
#include <SDL2/SDL_vulkan.h>
#include <vulkan/vulkan.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <vector>

struct VulkanContext {
    SDL_Window*          window = nullptr;
    VkInstance           instance = VK_NULL_HANDLE;
    VkSurfaceKHR         surface = VK_NULL_HANDLE;
    VkPhysicalDevice     pdev = VK_NULL_HANDLE;
    VkDevice             dev = VK_NULL_HANDLE;
    uint32_t             queue_family = 0;
    VkQueue              queue = VK_NULL_HANDLE;
    VkSwapchainKHR       swapchain = VK_NULL_HANDLE;
    VkFormat             format = VK_FORMAT_B8G8R8A8_UNORM;
    VkExtent2D           extent{};
    std::vector<VkImage> images;
    std::vector<VkImageView> image_views;
    VkCommandPool        cmd_pool = VK_NULL_HANDLE;
    VkCommandBuffer      cmd = VK_NULL_HANDLE;
    VkSemaphore          image_available = VK_NULL_HANDLE;
    VkSemaphore          render_done = VK_NULL_HANDLE;
    VkFence              in_flight = VK_NULL_HANDLE;
    VkBuffer             staging_buf = VK_NULL_HANDLE;
    VkDeviceMemory       staging_mem = VK_NULL_HANDLE;
    VkDeviceSize         staging_size = 0;
};

static uint32_t find_mem_type(VkPhysicalDevice pdev, uint32_t type_bits, VkMemoryPropertyFlags flags) {
    VkPhysicalDeviceMemoryProperties mem_props{};
    vkGetPhysicalDeviceMemoryProperties(pdev, &mem_props);
    for (uint32_t i = 0; i < mem_props.memoryTypeCount; ++i) {
        if ((type_bits & (1u << i)) && (mem_props.memoryTypes[i].propertyFlags & flags) == flags)
            return i;
    }
    return UINT32_MAX;
}

static void destroy_swapchain(VulkanContext& vc) {
    if (vc.dev == VK_NULL_HANDLE) {
        vc.image_views.clear();
        vc.images.clear();
        vc.swapchain = VK_NULL_HANDLE;
        vc.extent = {};
        return;
    }
    for (auto iv : vc.image_views) {
        vkDestroyImageView(vc.dev, iv, nullptr);
    }
    vc.image_views.clear();
    if (vc.swapchain != VK_NULL_HANDLE) {
        vkDestroySwapchainKHR(vc.dev, vc.swapchain, nullptr);
        vc.swapchain = VK_NULL_HANDLE;
    }
    vc.images.clear();
    vc.extent = {};
}

static void destroy_staging(VulkanContext& vc) {
    if (vc.dev == VK_NULL_HANDLE)
        return;
    if (vc.staging_buf != VK_NULL_HANDLE) {
        vkDestroyBuffer(vc.dev, vc.staging_buf, nullptr);
        vc.staging_buf = VK_NULL_HANDLE;
    }
    if (vc.staging_mem != VK_NULL_HANDLE) {
        vkFreeMemory(vc.dev, vc.staging_mem, nullptr);
        vc.staging_mem = VK_NULL_HANDLE;
    }
    vc.staging_size = 0;
}

static void vk_shutdown(PlatformContext& ctx) {
    if (!ctx.user) return;
    VulkanContext* vc = static_cast<VulkanContext*>(ctx.user);

    if (vc->dev != VK_NULL_HANDLE)
        vkDeviceWaitIdle(vc->dev);
    destroy_staging(*vc);

    if (vc->dev != VK_NULL_HANDLE) {
        if (vc->in_flight)    vkDestroyFence(vc->dev, vc->in_flight, nullptr);
        if (vc->image_available) vkDestroySemaphore(vc->dev, vc->image_available, nullptr);
        if (vc->render_done)  vkDestroySemaphore(vc->dev, vc->render_done, nullptr);
        if (vc->cmd_pool)     vkDestroyCommandPool(vc->dev, vc->cmd_pool, nullptr);
    }

    destroy_swapchain(*vc);

    if (vc->dev) vkDestroyDevice(vc->dev, nullptr);
    if (vc->surface) vkDestroySurfaceKHR(vc->instance, vc->surface, nullptr);
    if (vc->instance) vkDestroyInstance(vc->instance, nullptr);
    if (vc->window) SDL_DestroyWindow(vc->window);

    SDL_QuitSubSystem(SDL_INIT_VIDEO);

    delete vc;
    ctx.user = nullptr;
}

static bool create_instance_surface(VulkanContext& vc) {
    unsigned int ext_count = 0;
    if (!SDL_Vulkan_GetInstanceExtensions(vc.window, &ext_count, nullptr) || ext_count == 0)
        return false;
    std::vector<const char*> exts(ext_count);
    SDL_Vulkan_GetInstanceExtensions(vc.window, &ext_count, exts.data());

    VkApplicationInfo app_info{ VK_STRUCTURE_TYPE_APPLICATION_INFO };
    app_info.pApplicationName = "Hydra Vulkan Backend";
    app_info.applicationVersion = VK_MAKE_VERSION(0, 0, 1);
    app_info.pEngineName = "Hydra";
    app_info.engineVersion = VK_MAKE_VERSION(0, 0, 1);
    app_info.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo ci{ VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO };
    ci.pApplicationInfo = &app_info;
    ci.enabledExtensionCount = ext_count;
    ci.ppEnabledExtensionNames = exts.data();

    if (vkCreateInstance(&ci, nullptr, &vc.instance) != VK_SUCCESS)
        return false;

    if (!SDL_Vulkan_CreateSurface(vc.window, vc.instance, &vc.surface))
        return false;

    return true;
}

static bool pick_device_and_queue(VulkanContext& vc) {
    uint32_t count = 0;
    vkEnumeratePhysicalDevices(vc.instance, &count, nullptr);
    if (count == 0) return false;
    std::vector<VkPhysicalDevice> devs(count);
    vkEnumeratePhysicalDevices(vc.instance, &count, devs.data());

    for (auto d : devs) {
        uint32_t qcount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(d, &qcount, nullptr);
        std::vector<VkQueueFamilyProperties> qprops(qcount);
        vkGetPhysicalDeviceQueueFamilyProperties(d, &qcount, qprops.data());
        for (uint32_t i = 0; i < qcount; ++i) {
            VkBool32 present = VK_FALSE;
            vkGetPhysicalDeviceSurfaceSupportKHR(d, i, vc.surface, &present);
            if ((qprops[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) && present) {
                vc.pdev = d;
                vc.queue_family = i;
                return true;
            }
        }
    }
    return false;
}

static bool create_device(VulkanContext& vc) {
    float prio = 1.0f;
    VkDeviceQueueCreateInfo qci{ VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO };
    qci.queueFamilyIndex = vc.queue_family;
    qci.queueCount = 1;
    qci.pQueuePriorities = &prio;

    const char* dev_exts[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };
    VkDeviceCreateInfo dci{ VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO };
    dci.queueCreateInfoCount = 1;
    dci.pQueueCreateInfos = &qci;
    dci.enabledExtensionCount = 1;
    dci.ppEnabledExtensionNames = dev_exts;

    if (vkCreateDevice(vc.pdev, &dci, nullptr, &vc.dev) != VK_SUCCESS)
        return false;
    vkGetDeviceQueue(vc.dev, vc.queue_family, 0, &vc.queue);
    return true;
}

static VkSurfaceFormatKHR choose_format(const std::vector<VkSurfaceFormatKHR>& formats) {
    for (auto f : formats) {
        if (f.format == VK_FORMAT_B8G8R8A8_UNORM && f.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
            return f;
    }
    return formats[0];
}

static bool create_swapchain(VulkanContext& vc, int w, int h) {
    VkSurfaceCapabilitiesKHR caps{};
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(vc.pdev, vc.surface, &caps);
    uint32_t fmt_count = 0;
    vkGetPhysicalDeviceSurfaceFormatsKHR(vc.pdev, vc.surface, &fmt_count, nullptr);
    if (fmt_count == 0)
        return false;
    std::vector<VkSurfaceFormatKHR> formats(fmt_count);
    vkGetPhysicalDeviceSurfaceFormatsKHR(vc.pdev, vc.surface, &fmt_count, formats.data());
    VkSurfaceFormatKHR fmt = choose_format(formats);
    vc.format = fmt.format;

    VkExtent2D extent{};
    if (caps.currentExtent.width != UINT32_MAX) {
        extent = caps.currentExtent;
    } else {
        extent.width = static_cast<uint32_t>(w);
        extent.height = static_cast<uint32_t>(h);
        extent.width = std::max(caps.minImageExtent.width, std::min(caps.maxImageExtent.width, extent.width));
        extent.height = std::max(caps.minImageExtent.height, std::min(caps.maxImageExtent.height, extent.height));
    }
    vc.extent = extent;

    uint32_t image_count = caps.minImageCount + 1;
    if (caps.maxImageCount > 0 && image_count > caps.maxImageCount)
        image_count = caps.maxImageCount;

    VkSwapchainCreateInfoKHR sci{ VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR };
    sci.surface = vc.surface;
    sci.minImageCount = image_count;
    sci.imageFormat = fmt.format;
    sci.imageColorSpace = fmt.colorSpace;
    sci.imageExtent = extent;
    sci.imageArrayLayers = 1;
    sci.imageUsage = VK_IMAGE_USAGE_TRANSFER_DST_BIT;
    sci.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    sci.preTransform = caps.currentTransform;
    sci.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    sci.presentMode = VK_PRESENT_MODE_FIFO_KHR;
    sci.clipped = VK_TRUE;
    sci.oldSwapchain = vc.swapchain;

    VkSwapchainKHR new_sc = VK_NULL_HANDLE;
    if (vkCreateSwapchainKHR(vc.dev, &sci, nullptr, &new_sc) != VK_SUCCESS)
        return false;

    destroy_swapchain(vc);
    vc.swapchain = new_sc;

    uint32_t icount = 0;
    vkGetSwapchainImagesKHR(vc.dev, vc.swapchain, &icount, nullptr);
    vc.images.resize(icount);
    vkGetSwapchainImagesKHR(vc.dev, vc.swapchain, &icount, vc.images.data());

    vc.image_views.resize(icount);
    for (size_t i = 0; i < vc.images.size(); ++i) {
        VkImageViewCreateInfo ivci{ VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO };
        ivci.image = vc.images[i];
        ivci.viewType = VK_IMAGE_VIEW_TYPE_2D;
        ivci.format = vc.format;
        ivci.components = { VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY,
                            VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY };
        ivci.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        ivci.subresourceRange.levelCount = 1;
        ivci.subresourceRange.layerCount = 1;
        if (vkCreateImageView(vc.dev, &ivci, nullptr, &vc.image_views[i]) != VK_SUCCESS)
            return false;
    }
    return true;
}

static bool create_commands(VulkanContext& vc) {
    VkCommandPoolCreateInfo cpci{ VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO };
    cpci.queueFamilyIndex = vc.queue_family;
    cpci.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    if (vkCreateCommandPool(vc.dev, &cpci, nullptr, &vc.cmd_pool) != VK_SUCCESS)
        return false;

    VkCommandBufferAllocateInfo cbai{ VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO };
    cbai.commandPool = vc.cmd_pool;
    cbai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    cbai.commandBufferCount = 1;
    if (vkAllocateCommandBuffers(vc.dev, &cbai, &vc.cmd) != VK_SUCCESS)
        return false;
    return true;
}

static bool create_sync(VulkanContext& vc) {
    VkSemaphoreCreateInfo sci{ VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
    VkFenceCreateInfo fci{ VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };
    fci.flags = VK_FENCE_CREATE_SIGNALED_BIT;
    if (vkCreateSemaphore(vc.dev, &sci, nullptr, &vc.image_available) != VK_SUCCESS) return false;
    if (vkCreateSemaphore(vc.dev, &sci, nullptr, &vc.render_done) != VK_SUCCESS) return false;
    if (vkCreateFence(vc.dev, &fci, nullptr, &vc.in_flight) != VK_SUCCESS) return false;
    return true;
}

static bool ensure_staging(VulkanContext& vc, VkDeviceSize size) {
    if (vc.staging_buf != VK_NULL_HANDLE && vc.staging_size >= size)
        return true;
    destroy_staging(vc);

    VkBufferCreateInfo bci{ VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO };
    bci.size = size;
    bci.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
    bci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    if (vkCreateBuffer(vc.dev, &bci, nullptr, &vc.staging_buf) != VK_SUCCESS)
        return false;

    VkMemoryRequirements mr{};
    vkGetBufferMemoryRequirements(vc.dev, vc.staging_buf, &mr);
    uint32_t type = find_mem_type(vc.pdev, mr.memoryTypeBits,
                                  VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    if (type == UINT32_MAX)
        return false;

    VkMemoryAllocateInfo mai{ VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO };
    mai.allocationSize = mr.size;
    mai.memoryTypeIndex = type;
    if (vkAllocateMemory(vc.dev, &mai, nullptr, &vc.staging_mem) != VK_SUCCESS)
        return false;

    if (vkBindBufferMemory(vc.dev, vc.staging_buf, vc.staging_mem, 0) != VK_SUCCESS)
        return false;

    vc.staging_size = size;
    return true;
}

static bool vk_init(PlatformContext& ctx, const PlatformConfig& cfg) {
    if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0)
        return false;
    SDL_Window* win = SDL_CreateWindow(
        "Hydra Vulkan Backend",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        cfg.width * 2, cfg.height * 2,
        SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE
    );
    if (!win) {
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        return false;
    }

    VulkanContext* vc = new VulkanContext();
    vc->window = win;
    ctx.user = vc;

    if (!create_instance_surface(*vc) ||
        !pick_device_and_queue(*vc) ||
        !create_device(*vc) ||
        !create_swapchain(*vc, cfg.width, cfg.height) ||
        !create_commands(*vc) ||
        !create_sync(*vc)) {
        vk_shutdown(ctx);
        return false;
    }
    return true;
}

static void record_and_submit(VulkanContext& vc, uint32_t image_index, const uint32_t* pixels, int w, int h) {
    const VkDeviceSize copy_size = static_cast<VkDeviceSize>(w) * static_cast<VkDeviceSize>(h) * 4;
    if (!ensure_staging(vc, copy_size))
        return;

    void* data = nullptr;
    if (vkMapMemory(vc.dev, vc.staging_mem, 0, copy_size, 0, &data) != VK_SUCCESS)
        return;
    std::memcpy(data, pixels, static_cast<size_t>(copy_size));
    vkUnmapMemory(vc.dev, vc.staging_mem);

    vkWaitForFences(vc.dev, 1, &vc.in_flight, VK_TRUE, UINT64_MAX);
    vkResetFences(vc.dev, 1, &vc.in_flight);

    vkResetCommandBuffer(vc.cmd, 0);
    VkCommandBufferBeginInfo bi{ VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO };
    vkBeginCommandBuffer(vc.cmd, &bi);

    VkImage image = vc.images[image_index];

    VkImageMemoryBarrier barrier1{ VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER };
    barrier1.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    barrier1.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier1.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier1.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier1.image = image;
    barrier1.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier1.subresourceRange.levelCount = 1;
    barrier1.subresourceRange.layerCount = 1;
    barrier1.srcAccessMask = 0;
    barrier1.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

    vkCmdPipelineBarrier(vc.cmd,
                         VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT,
                         0, 0, nullptr, 0, nullptr, 1, &barrier1);

    VkBufferImageCopy region{};
    region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    region.imageSubresource.layerCount = 1;
    region.imageExtent = { static_cast<uint32_t>(w), static_cast<uint32_t>(h), 1 };
    vkCmdCopyBufferToImage(vc.cmd, vc.staging_buf, image,
                           VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    VkImageMemoryBarrier barrier2{ VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER };
    barrier2.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier2.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    barrier2.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier2.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier2.image = image;
    barrier2.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier2.subresourceRange.levelCount = 1;
    barrier2.subresourceRange.layerCount = 1;
    barrier2.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier2.dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;

    vkCmdPipelineBarrier(vc.cmd,
                         VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
                         0, 0, nullptr, 0, nullptr, 1, &barrier2);

    vkEndCommandBuffer(vc.cmd);

    VkPipelineStageFlags wait_stage = VK_PIPELINE_STAGE_TRANSFER_BIT;
    VkSubmitInfo si{ VK_STRUCTURE_TYPE_SUBMIT_INFO };
    si.waitSemaphoreCount = 1;
    si.pWaitSemaphores = &vc.image_available;
    si.pWaitDstStageMask = &wait_stage;
    si.commandBufferCount = 1;
    si.pCommandBuffers = &vc.cmd;
    si.signalSemaphoreCount = 1;
    si.pSignalSemaphores = &vc.render_done;
    vkQueueSubmit(vc.queue, 1, &si, vc.in_flight);
}

static void vk_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user || !pixels || w <= 0 || h <= 0) return;
    VulkanContext* vc = static_cast<VulkanContext*>(ctx.user);

    if (vc->swapchain == VK_NULL_HANDLE || vc->extent.width != static_cast<uint32_t>(w) || vc->extent.height != static_cast<uint32_t>(h)) {
        vkDeviceWaitIdle(vc->dev);
        create_swapchain(*vc, w, h);
    }

    uint32_t image_index = 0;
    VkResult ar = vkAcquireNextImageKHR(vc->dev, vc->swapchain, UINT64_MAX, vc->image_available, VK_NULL_HANDLE, &image_index);
    if (ar == VK_ERROR_OUT_OF_DATE_KHR) {
        vkDeviceWaitIdle(vc->dev);
        create_swapchain(*vc, w, h);
        return;
    }
    if (ar != VK_SUCCESS && ar != VK_SUBOPTIMAL_KHR)
        return;

    record_and_submit(*vc, image_index, pixels, w, h);

    VkPresentInfoKHR pi{ VK_STRUCTURE_TYPE_PRESENT_INFO_KHR };
    pi.waitSemaphoreCount = 1;
    pi.pWaitSemaphores = &vc->render_done;
    pi.swapchainCount = 1;
    pi.pSwapchains = &vc->swapchain;
    pi.pImageIndices = &image_index;
    VkResult pr = vkQueuePresentKHR(vc->queue, &pi);
    if (pr == VK_ERROR_OUT_OF_DATE_KHR || pr == VK_SUBOPTIMAL_KHR) {
        vkDeviceWaitIdle(vc->dev);
        create_swapchain(*vc, w, h);
    }
}

BackendOps get_ops_vulkan() {
    BackendOps ops;
    ops.init = vk_init;
    ops.present = vk_present;
    ops.shutdown = vk_shutdown;
    return ops;
}

#else

BackendOps get_ops_vulkan() {
    return make_stub_ops();
}

#endif
