/*************************************************************************
SmartHarvest SE
Copyright (c) Steve Townsend 2020

>>> SOURCE LICENSE >>>
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation (www.fsf.org); either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available at
http://www.fsf.org/licensing/licenses
>>> END OF LICENSE >>>
*************************************************************************/
#include "PrecompiledHeaders.h"

#include "WorldState/GameCalendar.h"

namespace shse
{

std::unique_ptr<GameCalendar> GameCalendar::m_instance;

GameCalendar& GameCalendar::Instance()
{
	if (!m_instance)
	{
		m_instance = std::make_unique<GameCalendar>();
	}
	return *m_instance;
}

GameCalendar::GameCalendar()
{
}

// Values from https://en.uesp.net/wiki/Lore:Calendar#Skyrim_Calendar
const std::vector<std::pair<std::string, unsigned int>> GameCalendar::m_monthDays = {
	{"Morning Star", 31},
	{"Sun's Dawn",	 28},
	{"First Seed",	 31},
	{"Rain's Hand",	 30},
	{"Second Seed",	 31},
	{"Midyear",		 30},
	{"Sun's Height", 31},
	{"Last Seed",	 31},
	{"Hearthfire",	 30},
	{"Frostfall",	 31},
	{"Sun's Dusk",	 30},
	{"Evening Star", 31}
};
const std::vector<std::string> GameCalendar::m_dayNames = {
	"Sundas",
	"Morndas",
	"Tirdas",
	"Middas",
	"Turdas",
	"Fredas",
	"Loredas"
};
const std::vector<std::string> GameCalendar::m_dayOfMonth = {
	"1st",
	"2nd",
	"3rd",
	"4th",
	"5th",
	"6th",
	"7th",
	"8th",
	"9th",
	"10th",
	"11th",
	"12th",
	"13th",
	"14th",
	"15th",
	"16th",
	"17th",
	"18th",
	"19th",
	"20th",
	"21st",
	"22nd",
	"23rd",
	"24th",
	"25th",
	"26th",
	"27th",
	"28th",
	"29th",
	"30th",
	"31st"
};

constexpr unsigned int GameCalendar::DaysPerYear() const
{
	unsigned int days(0);
	return std::accumulate(m_monthDays.cbegin(), m_monthDays.cend(), days,
		[&] (const unsigned int& total, const auto& value) { return total + value.second; });
}

constexpr const char* DateTimeFormat() {
	return "{H}.{m} {p} on {W}, {D} day of {M}, 4E {Y}";
}

std::string GameCalendar::DateTimeString(const float gameTime) const
{
	float daysPart(std::floor(gameTime));
	float timeOfDay(gameTime - daysPart);
	float hours(timeOfDay * 24.0f);
	float minutes((hours - std::floor(hours)) * 60.0f);
	bool isPM(hours >= 12.0f);
	// do not print 0 as the midnight hour
	if (hours == 0.0)
		hours = 12.0f;
	else if (hours > 12.0f)
		hours -= 12.0f;
	unsigned int elapsedDays(static_cast<unsigned int>(daysPart));
	unsigned int dayOfWeek(elapsedDays % 7);
	// count elapsed days to determine YMD
	unsigned int dayOfMonth(StartDay);
	unsigned int month(StartMonth);
	unsigned int year(StartYear);
	while (elapsedDays >= DaysPerYear())
	{
		++year;
		elapsedDays -= DaysPerYear();
	}
	while (elapsedDays >= m_monthDays[month].second - dayOfMonth + 1)
	{
		dayOfMonth = 1;
		++month;
		if (month >= m_monthDays.size())
		{
			month = 0;
			++year;
		}
		elapsedDays -= (m_monthDays[month].second - dayOfMonth + 1);
	}
	dayOfMonth += elapsedDays - 1;
	std::ostringstream dtString;
	dtString << unsigned int(hours) << '.' << std::setfill('0') << std::setw(2) << unsigned int(minutes) << (isPM ? "pm, " : "am, ");
	dtString << m_dayNames[dayOfWeek] << ", " << m_dayOfMonth[dayOfMonth] << " day of " << m_monthDays[month].first << ", 4E " << year;
	return dtString.str();
}

}