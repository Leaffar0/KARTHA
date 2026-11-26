// Build in this directory: cc -O2 -fPIC -shared -Wl,--as-needed clipboard.c -o libkartha_clipboard.so $(pkg-config --cflags --libs gtk+-3.0)
#include <gtk/gtk.h>

static GtkClipboard *clipboard;
static gchar *last_read;

static gboolean open_clipboard(void) {
    if (clipboard) return TRUE;
    // The Linux runner has an X11 window, including in a Wayland session.
    gtk_disable_setlocale();
    gdk_set_allowed_backends("x11");
    if (!gtk_init_check(NULL, NULL)) return FALSE;
    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    return clipboard != NULL;
}

const char *kartha_clipboard_read(void) {
    g_clear_pointer(&last_read, g_free);
    if (open_clipboard()) last_read = gtk_clipboard_wait_for_text(clipboard);
    return last_read ? last_read : "";
}

double kartha_clipboard_write(const char *text) {
    if (!open_clipboard()) return 0;
    gtk_clipboard_set_text(clipboard, text, -1);
    gchar *stored = gtk_clipboard_wait_for_text(clipboard);
    gboolean ok = g_strcmp0(text, stored) == 0;
    g_free(stored);
    if (ok) gtk_clipboard_store(clipboard);
    return ok;
}

// On desktops without a clipboard manager GTK serves paste requests itself.
double kartha_clipboard_poll(void) {
    if (clipboard) g_main_context_iteration(NULL, FALSE);
    return 0;
}
