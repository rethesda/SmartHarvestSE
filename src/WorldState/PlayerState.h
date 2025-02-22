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
#include "WorldState/LocationTracker.h"
#include "WorldState/InventoryCache.h"

namespace shse
{

class PlayerState
{
public:

	static PlayerState& Instance();
	PlayerState();

	inline bool IsValid() const { return m_valid;}

	void Refresh(const bool onMCMPush, const bool onGameReload);
	bool PerksAddLeveledItemsOnDeath() const;
	float PerkIngredientMultiplier() const;
	bool CanLoot() const;
	OwnershipRule EffectiveOwnershipRule() const { return m_ownershipRule; }
	SpecialObjectHandling BelongingsCheck() const { return m_belongingsCheck; }
	double SneakDistanceExterior() const;
	double SneakDistanceInterior() const;
	void ExcludeMountedIfForbidden(void);
	Position GetPosition() const;
	const RE::TESRace* GetRace() const;
	AlglibPosition GetAlglibPosition() const;
	void UpdateGameTime();
	inline float CurrentGameTime() const { return m_gameTime; }
	int ItemHeadroom(RE::TESBoundObject* form, const int delta) const;
	bool IsTimeSlowed() const { return m_slowedTime; }
	double ArrowMovingThreshold() const;
	inline RE::SpellItem* CarryWeightSpell() const { return m_carryWeightSpell; }
	inline RE::EffectSetting* CarryWeightEffect() const { return m_carryWeightEffect; }
	void ReviewExcessInventory(bool force);

private:
	void CheckPerks(const bool force);
	void ReconcileCarryWeight(const bool doReload);
	bool IsMagicallyConcealed(RE::MagicTarget* target) const;
	bool FortuneHuntOnly() const;

	static std::unique_ptr<PlayerState> m_instance;

	static constexpr int InfiniteWeight = 100000;
	static constexpr int PerkCheckIntervalSeconds = 15;
	std::chrono::time_point<std::chrono::high_resolution_clock> m_lastPerkCheck;
	bool m_perksAddLeveledItemsOnDeath;
	float m_harvestedIngredientMultiplier;

	// Excess inventory management
	std::chrono::time_point<std::chrono::high_resolution_clock> m_lastExcessCheck;
	// specialized cache of inventory items
	mutable InventoryCache m_currentItems;
	mutable InventoryUpdates m_updates;

	bool m_currentlyBeefedUp;
	RE::SpellItem* m_carryWeightSpell;
	RE::EffectSetting* m_carryWeightEffect;

	bool m_sneaking;
	bool m_slowedTime;
	OwnershipRule m_ownershipRule;
	SpecialObjectHandling m_belongingsCheck;
	bool m_disableWhileMounted;

	float m_gameTime;

	bool m_valid;
	mutable RecursiveLock m_playerLock;
};

}