#if !defined __HELPER_H__
#define __HELPER_H__ 1

#include <glib.h>

typedef enum {ROTATE = 1, MIRROR = 2} RotationType;

typedef struct {

	char              *image;
	int                n_frames;
	gboolean           flip;
	gboolean           is_north;
	gboolean           is_east;
	gfloat             latitude;
    gfloat             longitude;
	RotationType       rotation_type;
	guint              timeout;
	int                image_number;
} MoonHelper;
typedef MoonHelper MoonApplet;

#endif/* __HELPER_H__ */


