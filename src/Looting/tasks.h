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
#pragma once

#include "Looting/containerLister.h"
#include "Looting/IRangeChecker.h"
#include "VM/EventPublisher.h"
#include "VM/UIState.h"

#include <mutex>


namespace shse
{

class SearchTask
{
public:
#if _DEBUG
	// make sure load spike handling works OK
	static constexpr size_t MaxREFRSPerPass = 25;
#else
	static constexpr size_t MaxREFRSPerPass = 75;
#endif

	SearchTask(RE::TESObjectREFR* target, INIFile::SecondaryType targetType);

	static bool Init(void);
	void Run();

	static bool IsLockedForHarvest(const RE::TESObjectREFR* refr);
	static bool UnlockHarvest(const RE::TESObjectREFR* refr, const bool isSilent);

	static void SyncDone(const bool reload);
	static void ToggleCalibration(const bool glowDemo);

	static void PrepareForReload();
	static void AfterReload();
	static void Allow();
	static void Disallow();
	static bool IsAllowed();
	static void ResetRestrictions(const bool gameReload);
	static void DoPeriodicSearch();

	static RE::FormID LootedDynamicContainerFormID(const RE::TESObjectREFR* refr);
	static bool IsLootedContainer(const RE::TESObjectREFR* refr);

	static void OnGoodToGo(void);

private:
	static size_t PendingHarvestNotifications();
	static bool LockHarvest(const RE::TESObjectREFR* refr, const bool isSilent);
	static void Start();

	bool IsReferenceLockedContainer(const RE::TESObjectREFR* refr);
	static void ForgetLockedContainers();

	static void MarkDynamicContainerLooted(const RE::TESObjectREFR* refr);
	static void ResetLootedDynamicContainers();

	static void MarkContainerLooted(const RE::TESObjectREFR* refr);
	static void ResetLootedContainers();

	bool IsLootingForbidden(const INIFile::SecondaryType targetType);
	bool IsBookGlowable() const;

	static bool HasDynamicData(RE::TESObjectREFR* refr);
	static void RegisterActorTimeOfDeath(RE::TESObjectREFR* refr);

	// special object glow - not too long, in case we loot or move away
	static constexpr int ObjectGlowDurationSpecialSeconds = 10;
	// brief glow for looted objects and other purposes
	static constexpr int ObjectGlowDurationLootedSeconds = 2;

	static INIFile* m_ini;

	RE::TESObjectREFR* m_candidate;
	INIFile::SecondaryType m_targetType;

	static int m_crimeCheck;
	static SpecialObjectHandling m_belongingsCheck;

	static std::unordered_set<const RE::TESObjectREFR*> m_HarvestLock;
	static int m_pendingNotifies;

	static RecursiveLock m_searchLock;
	static bool m_threadStarted;
	static bool m_searchAllowed;

	static bool m_pluginSynced;

	static RecursiveLock m_lock;
	static std::unordered_map<const RE::TESObjectREFR*, std::chrono::time_point<std::chrono::high_resolution_clock>> m_glowExpiration;

	// Record looted containers to avoid re-scan of empty or looted chest and dead body. Resets on game reload or MCM settings update.
	static std::unordered_map<const RE::TESObjectREFR*, RE::FormID> m_lootedDynamicContainers;
	static std::unordered_set<const RE::TESObjectREFR*> m_lootedContainers;

	// BlackList for Locked Containers. Never auto-loot unless config permits. Reset on game reload.
	static std::unordered_set<const RE::TESObjectREFR*> m_lockedContainers;

	// Loot Range calibration setting
	static bool m_calibrating;
	static int m_calibrateRadius;
	static int m_calibrateDelta;
	static bool m_glowDemo;
	static GlowReason m_nextGlow;
	static constexpr int CalibrationRangeDelta = 3;
	static constexpr int MaxCalibrationRange = 100;
	static constexpr int GlowDemoRange = 30;

	// give the debug message time to catch up during calibration
	static constexpr int CalibrationDelay = 5;
	// short glow for loot range calibration and glow demo
	static constexpr int ObjectGlowDurationCalibrationSeconds = CalibrationDelay - 2;

	// Worker thread loop smallest possible delay
	static constexpr double MinDelay = 0.1;

	static bool m_pluginOK;

	GlowReason m_glowReason;
	inline void UpdateGlowReason(const GlowReason glowReason)
	{
		if (glowReason < m_glowReason)
			m_glowReason = glowReason;
	}

	static bool Load(void);
	static void TakeNap(void);
	static void ScanThread(void);

	
	void GetLootFromContainer(std::vector<std::tuple<InventoryItem, bool, bool>>& targets, const int animationType);
	void GlowObject(RE::TESObjectREFR* refr, const int duration, const GlowReason glowReason);
};

}