// ============================================================================
// backend_vulkan.h
// - Vulkan backend implementation using SDL2 for window management
// ============================================================================
#pragma once

#if defined(HYDRA_ENABLE_VULKAN) && (defined(__has_include) ? __has_include(<vulkan/vulkan.h>) && __has_include(<SDL2/SDL_vulkan.h>) : 0)

#include <SDL2/SDL.h>
#include <SDL2/SDL_vulkan.h>
#include <vulkan/vulkan.h>
#include <vector>
#include "backend_base.h"

class VulkanBackend : public Backend {
public:
    VulkanBackend();
    ~VulkanBackend() override;

    bool init(PlatformContext& ctx, const PlatformConfig& cfg) override;
    void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) override;
    void shutdown(PlatformContext& ctx) override;

private:
    struct VulkanContext {
        SDL_Window* window = nullptr;
        VkInstance instance = VK_NULL_HANDLE;
        VkSurfaceKHR surface = VK_NULL_HANDLE;
        VkPhysicalDevice pdev = VK_NULL_HANDLE;
        VkDevice dev = VK_NULL_HANDLE;
        uint32_t queue_family = 0;
        VkQueue queue = VK_NULL_HANDLE;
        VkSwapchainKHR swapchain = VK_NULL_HANDLE;
        VkFormat format = VK_FORMAT_B8G8R8A8_UNORM;
        VkExtent2D extent{};
        std::vector<VkImage> images;
        std::vector<VkImageView> image_views;
        VkCommandPool cmd_pool = VK_NULL_HANDLE;
        VkCommandBuffer cmd = VK_NULL_HANDLE;
        VkSemaphore image_available = VK_NULL_HANDLE;
        VkSemaphore render_done = VK_NULL_HANDLE;
        VkFence in_flight = VK_NULL_HANDLE;
        VkBuffer staging_buf = VK_NULL_HANDLE;
        VkDeviceMemory staging_mem = VK_NULL_HANDLE;
        VkDeviceSize staging_size = 0;
    };

    VulkanContext* context_ = nullptr;

    // Helper functions
    uint32_t find_memory_type(uint32_t type_bits, VkMemoryPropertyFlags flags);
    void destroy_swapchain();
    bool create_swapchain();
    bool create_image_views();
    bool create_command_pool();
    bool create_command_buffer();
    bool create_sync_objects();
    bool create_staging_buffer(VkDeviceSize size);
    bool record_command_buffer(const uint32_t* pixels, int w, int h);
};

#endif