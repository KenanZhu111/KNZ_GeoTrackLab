#include "brdm2pos.h"
using namespace std;
/* -------------------------------------------------------------------------- */
/// @brief convert UTC to GPS Second of week
/// @param y year
/// @param m month
/// @param d day
/// @param h hour
/// @param min minute
/// @param sec second
/// @return return GPS Second of week
/* -------------------------------------------------------------------------- */
double Time2GPST(int y, int m, int d, double h, int min, double sec)
{
	if (m > 2)
	{
		y = y;
		m = m;
	}

	if (m <= 2)
	{
		y = y - 1;
		m = m + 12;
	}

	h = h + min / 60.0 + sec / 3600.0;
	double JD = (int)(365.25 * y) + (int)(30.6001 * (m + 1)) + d + h / 24.0 + 1720981.5;
	double MJD = JD - 2400000.5;
	int gpsweek = (int)((MJD - 44244) / 7);
	double secofweek = (MJD - 44244.0 - gpsweek * 7.0) * 86400.0;
	return secofweek;
}
double JDUTC2GPST(double JD_UTCSU)
{
	double n;//Leap second

	if (2451179.5000000 < JD_UTCSU && JD_UTCSU < 2453736.5000000) { n = 32.0; }
	else if (2453736.5000000 < JD_UTCSU && JD_UTCSU < 2454832.5000000) { n = 33.0; }
	else if (2454832.5000000 < JD_UTCSU && JD_UTCSU < 2455927.5000000) { n = 34.0; }
	else if (2455927.5000000 < JD_UTCSU && JD_UTCSU < 2457023.5000000) { n = 35.0; }
	else if (2457023.5000000 < JD_UTCSU && JD_UTCSU < 2457754.5000000) { n = 36.0; }
	else if (2457754.5000000 < JD_UTCSU) { n = 37.0; }

	JD_UTCSU += ((n * 1 - 19) / 3600.0) / 24.0;
	double MJD = JD_UTCSU - 2400000.5;
	int gpsweek = (int)((MJD - 44244) / 7);
	double secofweek = (MJD - 44244.0 - gpsweek * 7.0) * 86400.0;
	return secofweek;
}
double UTCTime2JD(int y, int m, int d, double h, int min, double sec)
{
	if (m > 2)
	{
		y = y;
		m = m;
	}

	if (m <= 2)
	{
		y = y - 1;
		m = m + 12;
	}

	h = h + min / 60.0 + sec / 3600.0;
	double JD = (int)(365.25 * y) + (int)(30.6001 * (m + 1)) + d + h / 24.0 + 1720981.5;
	return JD;
}