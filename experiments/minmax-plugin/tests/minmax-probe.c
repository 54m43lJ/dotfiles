// Minimal xdg-shell probe: maps a toplevel and optionally asks the
// compositor to minimize/maximize it. Used to test the Hyprland plugin hook.

#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <wayland-client.h>

#include "xdg-shell-client-protocol.h"

struct probe_state {
    struct wl_display* display;
    struct wl_registry* registry;
    struct wl_compositor* compositor;
    struct wl_shm* shm;
    struct xdg_wm_base* wm_base;
    struct wl_surface* surface;
    struct xdg_surface* xdg_surface;
    struct xdg_toplevel* toplevel;
    struct wl_buffer* buffer;
    int width;
    int height;
    int mapped;
    int running;
};

static void xdg_wm_base_ping(void* data, struct xdg_wm_base* wm_base, uint32_t serial) {
    (void)data;
    xdg_wm_base_pong(wm_base, serial);
}

static const struct xdg_wm_base_listener wm_base_listener = {
    .ping = xdg_wm_base_ping,
};

static void xdg_surface_configure(void* data, struct xdg_surface* xdg_surface, uint32_t serial) {
    struct probe_state* state = data;

    xdg_surface_ack_configure(xdg_surface, serial);

    if (!state->mapped) {
        wl_surface_attach(state->surface, state->buffer, 0, 0);
        wl_surface_damage_buffer(state->surface, 0, 0, state->width, state->height);
        wl_surface_commit(state->surface);
        state->mapped = 1;
        printf("READY\n");
        fflush(stdout);
    }
}

static const struct xdg_surface_listener xdg_surface_listener = {
    .configure = xdg_surface_configure,
};

static void xdg_toplevel_configure(void* data, struct xdg_toplevel* toplevel, int32_t width, int32_t height,
                                   struct wl_array* states) {
    (void)data;
    (void)toplevel;
    (void)width;
    (void)height;
    (void)states;
}

static void xdg_toplevel_close(void* data, struct xdg_toplevel* toplevel) {
    (void)toplevel;
    struct probe_state* state = data;
    state->running = 0;
}

static const struct xdg_toplevel_listener toplevel_listener = {
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

static void registry_global(void* data, struct wl_registry* registry, uint32_t name, const char* interface,
                            uint32_t version) {
    struct probe_state* state = data;

    if (strcmp(interface, wl_compositor_interface.name) == 0) {
        state->compositor = wl_registry_bind(registry, name, &wl_compositor_interface, version < 4 ? version : 4);
    } else if (strcmp(interface, wl_shm_interface.name) == 0) {
        state->shm = wl_registry_bind(registry, name, &wl_shm_interface, 1);
    } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
        state->wm_base = wl_registry_bind(registry, name, &xdg_wm_base_interface, 1);
        xdg_wm_base_add_listener(state->wm_base, &wm_base_listener, state);
    }
}

static void registry_global_remove(void* data, struct wl_registry* registry, uint32_t name) {
    (void)data;
    (void)registry;
    (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static struct wl_buffer* create_buffer(struct probe_state* state) {
    const int stride = state->width * 4;
    const int size = stride * state->height;

    int fd = memfd_create("minmax-probe", MFD_CLOEXEC);
    if (fd < 0) {
        perror("memfd_create");
        return NULL;
    }
    if (ftruncate(fd, size) < 0) {
        perror("ftruncate");
        close(fd);
        return NULL;
    }

    void* data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return NULL;
    }
    memset(data, 0x33, size);

    struct wl_shm_pool* pool = wl_shm_create_pool(state->shm, fd, size);
    struct wl_buffer* buffer = wl_shm_pool_create_buffer(pool, 0, state->width, state->height, stride,
                                                          WL_SHM_FORMAT_ARGB8888);
    wl_shm_pool_destroy(pool);
    munmap(data, size);
    close(fd);
    return buffer;
}

int main(int argc, char** argv) {
    const char* action = NULL;
    int hold_seconds = 5;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--minimize") == 0)
            action = "minimize";
        else if (strcmp(argv[i], "--maximize") == 0)
            action = "maximize";
        else if (strcmp(argv[i], "--hold") == 0 && i + 1 < argc)
            hold_seconds = atoi(argv[++i]);
    }

    setvbuf(stdout, NULL, _IONBF, 0);

    struct probe_state state = {
        .width = 200,
        .height = 100,
        .running = 1,
    };

    state.display = wl_display_connect(NULL);
    if (!state.display) {
        fprintf(stderr, "cannot connect to Wayland display\n");
        return 1;
    }

    state.registry = wl_display_get_registry(state.display);
    wl_registry_add_listener(state.registry, &registry_listener, &state);
    wl_display_roundtrip(state.display);

    if (!state.compositor || !state.shm || !state.wm_base) {
        fprintf(stderr, "missing required globals (compositor=%p shm=%p xdg_wm_base=%p)\n",
                (void*)state.compositor, (void*)state.shm, (void*)state.wm_base);
        return 1;
    }

    state.buffer = create_buffer(&state);
    if (!state.buffer) {
        fprintf(stderr, "failed to create shm buffer\n");
        return 1;
    }

    state.surface = wl_compositor_create_surface(state.compositor);
    state.xdg_surface = xdg_wm_base_get_xdg_surface(state.wm_base, state.surface);
    xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state);

    state.toplevel = xdg_surface_get_toplevel(state.xdg_surface);
    xdg_toplevel_add_listener(state.toplevel, &toplevel_listener, &state);
    xdg_toplevel_set_title(state.toplevel, "minmax-probe");
    xdg_toplevel_set_app_id(state.toplevel, "minmax-probe");

    wl_surface_commit(state.surface);

    while (state.running && !state.mapped) {
        if (wl_display_dispatch(state.display) < 0) {
            fprintf(stderr, "wl_display_dispatch failed\n");
            return 1;
        }
    }

    if (!state.running)
        return 0;

    usleep(300000);

    if (action && strcmp(action, "minimize") == 0) {
        xdg_toplevel_set_minimized(state.toplevel);
        printf("SENT minimize\n");
    } else if (action && strcmp(action, "maximize") == 0) {
        xdg_toplevel_set_maximized(state.toplevel);
        printf("SENT maximize\n");
    }

    for (int i = 0; i < hold_seconds * 10 && state.running; ++i) {
        if (wl_display_roundtrip(state.display) < 0)
            break;
        usleep(100000);
    }

    if (state.toplevel)
        xdg_toplevel_destroy(state.toplevel);
    if (state.xdg_surface)
        xdg_surface_destroy(state.xdg_surface);
    if (state.surface)
        wl_surface_destroy(state.surface);
    if (state.buffer)
        wl_buffer_destroy(state.buffer);
    if (state.wm_base)
        xdg_wm_base_destroy(state.wm_base);
    if (state.shm)
        wl_shm_destroy(state.shm);
    if (state.compositor)
        wl_compositor_destroy(state.compositor);
    if (state.registry)
        wl_registry_destroy(state.registry);

    wl_display_disconnect(state.display);
    return 0;
}
