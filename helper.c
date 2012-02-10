#include "helper.h"
#define __GLUNARCLOCK_H__ 1
#include "moondata.h"

#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <X11/X.h>		/* need this for CurrentTime */

#include <libintl.h>

#include "MoonRise.h"
#include "moondata.h"
#include "CalcEphem.h"

#define _ gettext

#define RADIUS_OF_EARTH 6371	/* kilometers */

typedef struct CTrans MoonData;
MoonData moondata;

gboolean 
visible()
{
	return moondata.Visible;
}

gdouble
moonphase()
{
	return moondata.MoonPhase;
}

static void 
format_time(gchar * buf, gint size, gdouble time)
{
	gint hour, min, sec;

	hour = (gint) (time);

	min = (gint) ((ABS(time - hour)) * 60);

	sec = (gint) (ABS(ABS((time - hour)*60)-min)*60);

	g_snprintf(buf, size, "%02d:%02d:%02d", hour, min, sec);

	return;
}

static void
mod_time(gdouble * time)
{
	g_assert(time);

	if (*time < 0.0)
		*time += 24.0;
	else if (*time > 24.0)
		*time -= 24.0;

	return;
}

static void 
format_angle_hours(gchar * buf, gint size, gdouble angle)
{
	gint hour, min, sec;

	hour = (gint) (angle / 15.0);
	min = (gint) ((ABS(angle - hour * 15.0)) * 4.0);
	sec = (gint) (ABS(ABS((angle - hour * 15.0)*4.0)-min)*60);

	g_snprintf(buf, size, "%02d:%02d:%02d", hour, min, sec);

	return;
}


static void
calc_riseset_time(gchar * buf, gchar * buf2, gint size, CTrans * c)
{
	gdouble rise, set;

	MoonRise(c, &rise, &set);

	if (ABS(rise) > 24.0)
		g_snprintf(buf, size, _("no rise"));
	else{
/* 		rise = rise + (moondata.LST-moondata.UT); */
/* 		mod_time(&rise); */
		format_time(buf, size, rise);
	}
	if (ABS(set) > 24.0)
		g_snprintf(buf2, size, _("no set"));
	else{
/* 		set = set + (moondata.LST-moondata.UT); */
/* 		mod_time(&set); */
		format_time(buf2, size, set);
	}
}

void 
update_moondata(MoonHelper * moon)
{
	struct tm *time_struc;	/* The tm struct is defined in <time.h> */
	gdouble local_std_time, univ_time, eot;
	glong current_gmt, date;
	gint day_of_month, month, year;

	current_gmt = time(CurrentTime);/* CurrentTime defined in <X11/X.h> */

	time_struc = gmtime(&current_gmt);
	univ_time =
	    time_struc->tm_hour + time_struc->tm_min / 60.0 +
	    time_struc->tm_sec / 3600.0;

	/* The date needs to be the date in UTC, i.e. in greenwich, so
	 * be sure not to call the localtime function until after date
	 * has been set (there's only one tm structure).  */

	year = time_struc->tm_year + 1900;
	month = time_struc->tm_mon + 1;
	day_of_month = time_struc->tm_mday;

	date = year * 10000 + month * 100 + day_of_month;

	time_struc = localtime(&current_gmt);
	local_std_time =
	    time_struc->tm_hour + time_struc->tm_min / 60.0 +
	    time_struc->tm_sec / 3600.0;

	/* CalcEphem assumes longitude degrees west to be positive
	 * and degrees east negative.  I think the opposite convention
	 * is more intuitive, since degrees east means you add
	 * time to gmt, but we'll stick to CalcEphem's convention to
	 * prevent mixups. */

	moondata.Glat = moon->is_north ?  moon->latitude : -moon->latitude;
	moondata.Glon = moon->is_east  ? -moon->longitude : moon->longitude ;

	CalcEphem(date, univ_time, &moondata);


	/* eot is the equation of time. gmst is Greenwich Sidereal
	 * Time.  This equation below is correct, but confusing at
	 * first.  It's easy to see when you draw the following
	 * picture: A sphere with 0 and 180 degree longitude, North on
	 * top, a meridian for the real sun, a meridian for a fictive
	 * average sun, a meridian denoting the vernal equinox.  Note
	 * that universal time is the hour angle between 180 degrees
	 * and the fictive sun's meridian measured clockwise.  gmst is
	 * the hour angle between 0 degrees and the meridian of the
	 * vernal equinox measured clockwise.  RA_sun/15.0 is the hour
	 * angle of the real sun measured counterclockwise from the
	 * vernal equinox. eot is the difference between the real and
	 * the fictive sun.  Looking at the picture, it's easy to see
	 * that 12=RA_sun/15-gmst+eot+utc (12 hours = 180 deg.) */

	eot =
	    12.0 - univ_time + moondata.gmst - moondata.RA_sun / 15.0;

	mod_time(&eot);

	moondata.LST = local_std_time;

	moondata.LMT = univ_time - moondata.Glon / 15.0;
	mod_time(&moondata.LMT);

	moondata.LSD =  (moondata.gmst - moondata.Glon / 15.0);
	mod_time(&moondata.LSD);

	moondata.LAT = moondata.LMT + eot;
	mod_time(&moondata.LAT);
}

static void
update_image_number (MoonApplet * moon)
{
	gdouble image_float;
	gint image_int;

	/* MoonPhase expresses phase of moon as fraction of 1; 0.5=full. */
	image_float = moonphase() * (gdouble) (moon->n_frames);
	image_int = (gint) image_float;

	/* ergo image number ranges from 0 to (frames - 1), which is why
	 * it's mod frames and not mod (frames + 1). */
	moon->image_number = ((image_float - image_int) >= 0.5) ?
	    (image_int + 1)
		% moon->n_frames : image_int % moon->n_frames;

	return;
}

int main(int argc, char * const argv[])
{
	MoonHelper moon = {};
	int opt;
	gchar rise[512] = "";
	gchar set[512] = "";

	textdomain("glunarclock");

	/* defaults: 56 frames, Le Kremlin Bicêtre */
	moon.latitude = 48.814028;
	moon.longitude = 2.36075;
	moon.is_north = 1;
	moon.is_east = 1;
	moon.n_frames = 56;

	while ((opt = getopt(argc, argv, "f:o:a:")) != -1) {
	   switch (opt) {
	   case 'f':
			moon.n_frames = atoi(optarg);
			break;
	   case 'o':
			moon.longitude = atof(optarg);
			if (moon.longitude < 0) { moon.longitude *= -1; moon.is_east = 0; }
			break;
	   case 'a':
			moon.latitude = atof(optarg);
			if (moon.latitude < 0) { moon.latitude *= -1; moon.is_north = 0; }
			break;
	   default: /* '?' */
		   exit(EXIT_FAILURE);
	   }
	}
	update_moondata(&moon);
	update_image_number(&moon);
	calc_riseset_time(rise, set, 510, &moondata);
	printf("{\"image_number\": %d, \"full_moon\": %g, \"new_moon\": %g, "
			"\"altitude\": %g, \"azimuth\": %g, \"phase\": %.4g, "
			"\"rise\": \"%s\", \"set\": \"%s\"}\n", 
			moon.image_number, moondata.FullMoon, moondata.NewMoon, 
			moondata.h_moon, moondata.A_moon, moondata.MoonPhase * 100,
			rise, set);
	return 0;
}

