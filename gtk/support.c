#include <glib-object.h>
#include <gtk/gtkwidget.h>
#include <gdk/gdkwindow.h>
#include <gtk/gtkdialog.h>
#include <gtk/gtkfixed.h>
#include <gtk/gtkmenushell.h>
#include <gtk/gtkmenu.h>

typedef GtkFixed Fixed;
typedef GtkFixedClass FixedClass;

static void fixed_size_allocate (GtkWidget *widget, GtkAllocation *allocation);

G_DEFINE_TYPE (Fixed, fixed, GTK_TYPE_FIXED)

static void
fixed_class_init (FixedClass *class) {
  GTK_WIDGET_CLASS(class)->size_allocate = fixed_size_allocate;
}

static void
fixed_init (Fixed *fixed) {
}

GtkWidget *
fixed_new (void)
{
  return g_object_new (fixed_get_type (), NULL);
}

static void
fixed_size_allocate (GtkWidget *widget, GtkAllocation *allocation)
{

  widget->allocation = *allocation;

  if (!GTK_WIDGET_NO_WINDOW (widget))
    {
      if (GTK_WIDGET_REALIZED (widget))
	gdk_window_move_resize (widget->window,
				allocation->x, 
				allocation->y,
				allocation->width, 
				allocation->height);
    }
}

GType g_type_from_instance (GTypeInstance* instance) {
    return G_TYPE_FROM_INSTANCE(instance);
}

GType g_value_type (GValue* value) {
    return G_VALUE_TYPE(value);
}

int sizeof_gvalue() {
    return sizeof(GValue);
}

int sizeof_gclosure() {
    return sizeof(GClosure);
}

int g_is_value (GValue* value) {
    return G_IS_VALUE(value);
}

GdkWindow* gtk_widget_get_window (GtkWidget* widget) {
    return widget->window;
}

int gtk_widget_get_state (GtkWidget* widget) {
    return GTK_WIDGET_STATE(widget);
}

GtkWidget* gtk_dialog_get_vbox (GtkDialog* dialog) {
    return GTK_DIALOG(dialog)->vbox;
}

GtkWidget* gtk_dialog_get_action_area (GtkDialog* dialog) {
    return GTK_DIALOG(dialog)->action_area;
}

GtkAllocation* gtk_widget_get_allocation (GtkWidget* widget) {
    return &(widget->allocation);
}

void g_value_nullify(GValue* gvalue) {
    char* foo = (char*)gvalue;
    int i;

    for(i=0; i<sizeof(GValue); i++,foo++)
      *foo = 0;
}

void gtk_menu_shell_set_ignore_enter (GtkMenuShell* menu, gboolean value) {
  menu->ignore_enter = value ? TRUE : FALSE;
}

guint32 mytime = 0;
void gtk_set_button_time (GdkEventButton *button) {
  mytime = button->time;
}
  
void popup_gtk_menu (GtkMenu* menu, guint button) {
  g_print("%d mytime\n", mytime);
  gtk_menu_popup(menu, NULL, NULL, NULL, NULL, button, mytime);
}
