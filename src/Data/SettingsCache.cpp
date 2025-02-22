/*************************************************************************
SmartHarvest SE
Copyright (c) Steve Townsend 2021

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

#include "Data/SettingsCache.h"
#include "Data/iniSettings.h"
#include "Looting/Objects.h"
#include "WorldState/LocationTracker.h"
#include "Utilities/utils.h"

namespace shse
{

std::unique_ptr<SettingsCache> SettingsCache::m_instance;

SettingsCache& SettingsCache::Instance()
{
	if (!m_instance)
	{
		m_instance = std::make_unique<SettingsCache>();
	}
	return *m_instance;
}

SettingsCache::SettingsCache()
{
	// set new game defaults pending data load and refresh
	m_outdoorsRadius = 45.0 / DistanceUnitInFeet;
	m_indoorsRadius = 25.0 / DistanceUnitInFeet;
	m_verticalFactor = 1.0;
	m_respectDoors = false;
	m_unencumberedInPlayerHome = false;
	m_unencumberedIfWeaponDrawn = false;
	m_unencumberedInCombat = false;
	m_disableDuringCombat = false;
	m_disableWhileWeaponIsDrawn = false;
	m_disableWhileConcealed = false;
	m_fortuneHuntingEnabled = false;
	m_fortuneHuntItem = false;
	m_fortuneHuntNPC = false;
	m_fortuneHuntContainer = false;
	m_collectionsEnabled = false;
	m_notifyLocationChange = false;
	m_valuableItemThreshold = 500.0;
	m_checkWeightlessValue = false;
	m_weightlessMinimumValue = 10;
	m_valueWeightDefault = 10.0;
	m_deadBodyLooting = DeadBodyLooting::LootExcludingArmor;
	m_enchantedObjectHandling = EnchantedObjectHandling::DoLoot;
	m_delaySeconds = 1.2;
	m_delaySecondsIndoors = 0.6;
	m_crimeCheckSneaking = OwnershipRule::DisallowCrime;
	m_crimeCheckNotSneaking = OwnershipRule::DisallowCrime;
	m_playerBelongingsLoot = SpecialObjectHandling::DoNotLoot;
	m_lockedChestLoot = LockedContainerHandling::GlowTarget;
	m_bossChestLoot = SpecialObjectHandling::GlowTarget;
	m_valuableItemLoot = SpecialObjectHandling::DoLoot;
	m_playContainerAnimation = ContainerAnimationHandling::Glow;
	m_questObjectLoot = QuestObjectHandling::GlowTarget;
	m_enableLootContainer = true;
	m_enableHarvest = true;
	m_lootAllowedItemsInSettlement = true;
	m_lootAllowedItemsInPlayerHouse = true;
	m_unknownIngredientLoot = false;
	m_whiteListTargetNotify = false;
	m_manualLootTargetNotify = true;
	m_preventPopulationCenterLooting = PopulationCenterSize::Settlements;
	m_maxMiningItems = 8;
	m_miningToolsRequired = false;
	m_disallowMiningIfSneaking = false;

	m_lootingType.fill(LootingType::LootIfValuableEnoughNotify);
	m_excessHandling.fill(ExcessInventoryHandling::NoLimits);
	m_excessCount.fill(0);
	m_excessWeight.fill(0.0);
	m_valueWeight.fill(0.0);
	m_saleValuePercentMultiplier = 25.0;
	m_handleExcessCraftingItems = false;
	m_craftingItemsExcessHandling = ExcessInventoryHandling::NoLimits;
	m_craftingItemsExcessCount = 0;
	m_craftingItemsExcessWeight = 0.0;
}

void SettingsCache::Refresh(void)
{
	REL_VMESSAGE("Refresh settings cache");
	INIFile* ini(INIFile::GetInstance());

	// Value for feet per unit from https://www.creationkit.com/index.php?title=Unit
	double dSetting(ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "RadiusFeet"));
	m_outdoorsRadius = dSetting / DistanceUnitInFeet;
	REL_VMESSAGE("Search radius outdoors {:0.2f} feet -> {:0.2f} units", dSetting, m_outdoorsRadius);

	dSetting = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "IndoorsRadiusFeet");
	m_indoorsRadius = dSetting / DistanceUnitInFeet;
	REL_VMESSAGE("Search radius indoors {:0.2f} feet -> {:0.2f} units", dSetting, m_indoorsRadius);

	m_verticalFactor = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "VerticalRadiusFactor");
	REL_VMESSAGE("Vertical search radius factor {:0.2f}", m_verticalFactor);

	m_respectDoors = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "DoorsPreventLooting") != 0.;
	REL_VMESSAGE("Respect Doors as loot barriers {}", m_respectDoors);

	m_unencumberedInPlayerHome = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "UnencumberedInPlayerHome") != 0.0;
	REL_VMESSAGE("Unencumbered in Player House {}", m_unencumberedInPlayerHome);
	m_unencumberedIfWeaponDrawn = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "UnencumberedIfWeaponDrawn") != 0.0;
	REL_VMESSAGE("Unencumbered if weapon drawn {}", m_unencumberedIfWeaponDrawn);
	m_unencumberedInCombat = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "UnencumberedInCombat") != 0.0;
	REL_VMESSAGE("Unencumbered when in combat {}", m_unencumberedInCombat);

	m_disableDuringCombat = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "DisableDuringCombat") != 0.0;
	REL_VMESSAGE("Disable during combat {}", m_disableDuringCombat);
	m_disableWhileWeaponIsDrawn = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "DisableWhileWeaponIsDrawn") != 0.0;
	REL_VMESSAGE("Disable while weapon is drawn {}", m_disableWhileWeaponIsDrawn);
	m_disableWhileConcealed = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "DisableWhileConcealed") != 0.0;
	REL_VMESSAGE("Disable while concealed {}", m_disableWhileConcealed);
	m_fortuneHuntingEnabled = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "FortuneHuntingEnabled") != 0.0;
	REL_VMESSAGE("Fortune Hunting Enabled {}", m_fortuneHuntingEnabled);
	m_fortuneHuntItem = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "FortuneHuntItem") != 0.0;
	REL_VMESSAGE("Fortune Hunt Item {}", m_fortuneHuntItem);
	m_fortuneHuntNPC = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "FortuneHuntNPC") != 0.0;
	REL_VMESSAGE("Fortune Hunt NPC {}", m_fortuneHuntNPC);
	m_fortuneHuntContainer = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "FortuneHuntContainer") != 0.0;
	REL_VMESSAGE("Fortune Hunt Container {}", m_fortuneHuntContainer);
	m_collectionsEnabled = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "CollectionsEnabled") != 0.0;
	REL_VMESSAGE("Collections Enabled {}", m_collectionsEnabled);
	m_notifyLocationChange = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "NotifyLocationChange") != 0.0;
	REL_VMESSAGE("Notify Player of Location Change {}", m_notifyLocationChange);

	m_valuableItemThreshold = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "ValuableItemThreshold");
	REL_VMESSAGE("Valuable Item Threshold {:0.2f}", m_valuableItemThreshold);
	m_checkWeightlessValue = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::valueWeight, "CheckWeightlessValue") != 0.0;
	REL_VMESSAGE("Check Weightless Value {}", m_checkWeightlessValue);
	m_weightlessMinimumValue = static_cast<int>(ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::valueWeight, "WeightlessMinimumValue"));
	REL_VMESSAGE("Weightless Minimum Value {}", m_weightlessMinimumValue);
	m_valueWeightDefault = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "ValueWeightDefault");
	REL_VMESSAGE("Value Weight Default {:0.2f}", m_valueWeightDefault);

	auto vw(m_valueWeight.begin());
	auto lootingType(m_lootingType.begin());
	auto excessHandling(m_excessHandling.begin());
	auto excessCount(m_excessCount.begin());
	auto excessWeight(m_excessWeight.begin());
	for (size_t index = 1; index <= TypeCount; ++index, ++vw, ++lootingType, ++excessHandling, ++excessCount, ++excessWeight)
	{
		std::string typeName(GetObjectTypeName(ObjectType(index)));
		*vw = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::valueWeight, typeName);
		REL_VMESSAGE("Value Weight {:0.2f} for {} items", *vw, typeName);
		*lootingType = LootingTypeFromIniSetting(
			ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::itemObjects, typeName));
		REL_VMESSAGE("Looting Type {} for {} items", LootingTypeString(*lootingType), typeName);
		*excessHandling = ExcessInventoryHandlingFromIniSetting(
			ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::excessHandling, typeName));
		REL_VMESSAGE("Excess Handling {} for {} items", ExcessInventoryHandlingString(*excessHandling), typeName);
		*excessCount = static_cast<int>(
			ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::maxItems, typeName));
		REL_VMESSAGE("Excess Count {} for {} items", *excessCount, typeName);
		*excessWeight = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::maxWeight, typeName);
		REL_VMESSAGE("Excess Weight {:0.2f} for {} items", *excessWeight, typeName);
	}
	// convert from percentage to multiplier
	m_saleValuePercentMultiplier = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "SaleValuePercent") / 100.0;
	REL_VMESSAGE("Sale Value Percent Multiplier {}", m_saleValuePercentMultiplier);
	m_handleExcessCraftingItems = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "HandleExcessCraftingItems") != 0;
	REL_VMESSAGE("Handle Excess Crafting Items {}", m_handleExcessCraftingItems);
	m_craftingItemsExcessHandling = ExcessInventoryHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "CraftingItemsExcessHandling"));
	REL_VMESSAGE("Crafting Item Excess Handling {}", ExcessInventoryHandlingString(m_craftingItemsExcessHandling));
	m_craftingItemsExcessCount = static_cast<int>(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "CraftingItemsExcessCount"));
	REL_VMESSAGE("Crafting Items Excess Count {}", m_craftingItemsExcessCount);
	m_craftingItemsExcessWeight = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "CraftingItemsExcessWeight");
	REL_VMESSAGE("Crafting Items Excess Weight {:0.2f}", m_craftingItemsExcessWeight);

	m_deadBodyLooting = DeadBodyLootingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "EnableLootDeadbody"));
	REL_VMESSAGE("Dead Body Looting Type {}", DeadBodyLootingString(m_deadBodyLooting));
	m_enchantedObjectHandling = EnchantedObjectHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "EnchantedItemLoot"));
	REL_VMESSAGE("Enchanted Object Handling {}", EnchantedObjectHandlingString(m_enchantedObjectHandling));

	m_delaySeconds = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "IntervalSeconds");
	REL_VMESSAGE("Scan interval {:0.2f} seconds", m_delaySeconds);
	m_delaySecondsIndoors = ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "IndoorsIntervalSeconds");
	REL_VMESSAGE("Scan interval indoors {:0.2f} seconds", m_delaySecondsIndoors);

	m_crimeCheckSneaking = OwnershipRuleFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "CrimeCheckSneaking"));
	REL_VMESSAGE("Crime Check Sneaking {}", OwnershipRuleName(m_crimeCheckSneaking));
	m_crimeCheckNotSneaking = OwnershipRuleFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "CrimeCheckNotSneaking"));
	REL_VMESSAGE("Crime Check Not Sneaking {}", OwnershipRuleName(m_crimeCheckNotSneaking));
	m_playerBelongingsLoot = SpecialObjectHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "PlayerBelongingsLoot"));
	REL_VMESSAGE("Player Belongings Loot {}", SpecialObjectHandlingName(m_playerBelongingsLoot));
	m_lockedChestLoot = LockedContainerHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "LockedChestLoot"));
	REL_VMESSAGE("Locked Chest Loot {}", LockedContainerHandlingName(m_lockedChestLoot));
	m_bossChestLoot = SpecialObjectHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "BossChestLoot"));
	REL_VMESSAGE("Boss Chest Loot {}", SpecialObjectHandlingName(m_bossChestLoot));
	m_valuableItemLoot = SpecialObjectHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "ValuableItemLoot"));
	REL_VMESSAGE("Valuable Item Loot {}", SpecialObjectHandlingName(m_valuableItemLoot));
	m_playContainerAnimation = ContainerAnimationHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "PlayContainerAnimation"));
	REL_VMESSAGE("Play Container Animation {}", ContainerAnimationHandlingName(m_playContainerAnimation));
	m_questObjectLoot = QuestObjectHandlingFromIniSetting(
		ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "QuestObjectLoot"));
	REL_VMESSAGE("Quest Object Loot {}", QuestObjectHandlingName(m_questObjectLoot));

	m_enableLootContainer = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "EnableLootContainer") != 0.0;
	REL_VMESSAGE("Enable Loot Container {}", m_enableLootContainer);
	m_enableHarvest = ini->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "EnableHarvest") != 0.0;
	REL_VMESSAGE("Enable Harvest {}", m_enableHarvest);

	m_lootAllowedItemsInSettlement = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "LootAllowedItemsInSettlement") != 0;
	REL_VMESSAGE("Loot Allowed Items In Settlement {}", m_lootAllowedItemsInSettlement);
	m_lootAllowedItemsInPlayerHouse = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "LootAllowedItemsInPlayerHouse") != 0;
	REL_VMESSAGE("Loot Allowed Items In Player House {}", m_lootAllowedItemsInPlayerHouse);
	m_unknownIngredientLoot = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "UnknownIngredientLoot") != 0;
	REL_VMESSAGE("Unknown Ingredient Loot {}", m_unknownIngredientLoot);
	m_whiteListTargetNotify = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "WhiteListTargetNotify") != 0;
	REL_VMESSAGE("White List Target Notify {}", m_whiteListTargetNotify);
	m_manualLootTargetNotify = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "ManualLootTargetNotify") != 0;
	REL_VMESSAGE("Manual Loot Target Notify {}", m_manualLootTargetNotify);

	m_preventPopulationCenterLooting = PopulationCenterSizeFromIniSetting(
		INIFile::GetInstance()->GetSetting(INIFile::PrimaryType::common, INIFile::SecondaryType::config, "PreventPopulationCenterLooting"));
	REL_VMESSAGE("Prevent Population Center Looting {}", PopulationCenterSizeName(m_preventPopulationCenterLooting));
	m_maxMiningItems = static_cast<int16_t>(ini->GetSetting(INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "MaxMiningItems"));
	REL_VMESSAGE("Max Mining Items {}", m_maxMiningItems);
	m_miningToolsRequired = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "MiningToolsRequired") != 0;
	REL_VMESSAGE("Mining Tools Required {}", m_miningToolsRequired);
	m_disallowMiningIfSneaking = ini->GetSetting(
		INIFile::PrimaryType::harvest, INIFile::SecondaryType::config, "DisallowMiningIfSneaking") != 0;
	REL_VMESSAGE("Disallow mining if sneaking {}", m_disallowMiningIfSneaking);
}

double SettingsCache::OutdoorsRadius() const
{
	return m_outdoorsRadius;
}
double SettingsCache::IndoorsRadius() const
{
	return m_indoorsRadius;
}
double SettingsCache::VerticalFactor() const
{
	return m_verticalFactor;
}
bool SettingsCache::RespectDoors() const
{
	return m_respectDoors;
}
bool SettingsCache::UnencumberedInPlayerHome() const
{
	return m_unencumberedInPlayerHome;
}
bool SettingsCache::UnencumberedIfWeaponDrawn() const
{
	return m_unencumberedIfWeaponDrawn;
}
bool SettingsCache::UnencumberedInCombat() const
{
	return m_unencumberedInCombat;
}
bool SettingsCache::DisableDuringCombat() const
{
	return m_disableDuringCombat;
}
bool SettingsCache::DisableWhileWeaponIsDrawn() const
{
	return m_disableWhileWeaponIsDrawn;
}
bool SettingsCache::DisableWhileConcealed() const
{
	return m_disableWhileConcealed;
}
bool SettingsCache::FortuneHuntingEnabled() const
{
	return m_fortuneHuntingEnabled;
}
bool SettingsCache::FortuneHuntItem() const
{
	// main toggle can be cleared in MCM without resetting scoping flags
	return m_fortuneHuntingEnabled && m_fortuneHuntItem;
}
bool SettingsCache::FortuneHuntNPC() const
{
	// main toggle can be cleared in MCM without resetting scoping flags
	return m_fortuneHuntingEnabled && m_fortuneHuntNPC;
}
bool SettingsCache::FortuneHuntContainer() const
{
	// main toggle can be cleared in MCM without resetting scoping flags
	return m_fortuneHuntingEnabled && m_fortuneHuntContainer;
}
bool SettingsCache::CollectionsEnabled() const
{
	return m_collectionsEnabled;
}
bool SettingsCache::NotifyLocationChange() const
{
	return m_notifyLocationChange;
}
double SettingsCache::ValuableItemThreshold() const
{
	return m_valuableItemThreshold;
}
bool SettingsCache::CheckWeightlessValue() const
{
	return m_checkWeightlessValue;
}
int SettingsCache::WeightlessMinimumValue() const
{
	return m_weightlessMinimumValue;
}
double SettingsCache::ValueWeightDefault() const
{
	return m_valueWeightDefault;
}
double SettingsCache::ValueWeight(ObjectType objectType) const
{
	size_t index(std::min(TypeCount, size_t(objectType)) - 1);
	return m_valueWeight[index];
}
LootingType SettingsCache::ObjectLootingType(ObjectType objectType) const
{
	size_t index(std::min(TypeCount, size_t(objectType)) - 1);
	return m_lootingType[index];
}
ExcessInventoryHandling SettingsCache::ExcessInventoryHandlingType(ObjectType objectType) const
{
	size_t index(std::min(TypeCount, size_t(objectType)) - 1);
	return m_excessHandling[index];
}
int SettingsCache::ExcessInventoryCount(ObjectType objectType) const
{
	size_t index(std::min(TypeCount, size_t(objectType)) - 1);
	return m_excessCount[index];
}
double SettingsCache::ExcessInventoryWeight(ObjectType objectType) const
{
	size_t index(std::min(TypeCount, size_t(objectType)) - 1);
	return m_excessWeight[index];
}
double SettingsCache::SaleValuePercentMultiplier() const
{
	return m_saleValuePercentMultiplier;
}
bool SettingsCache::HandleExcessCraftingItems() const
{
	return m_handleExcessCraftingItems;
}
ExcessInventoryHandling SettingsCache::CraftingItemsExcessHandling() const
{
	return m_craftingItemsExcessHandling;
}
int SettingsCache::CraftingItemsExcessCount() const
{
	return m_craftingItemsExcessCount;
}
double SettingsCache::CraftingItemsExcessWeight() const
{
	return m_craftingItemsExcessWeight;
}
DeadBodyLooting SettingsCache::DeadBodyLootingType() const
{
	return m_deadBodyLooting;
}
EnchantedObjectHandling SettingsCache::EnchantedObjectHandlingType() const
{
	return m_enchantedObjectHandling;
}
double SettingsCache::DelaySeconds() const
{
	double delay(LocationTracker::Instance().IsPlayerIndoors() ? m_delaySecondsIndoors : m_delaySeconds);
	return std::max(MinThreadDelaySeconds, delay);
}
OwnershipRule SettingsCache::CrimeCheckSneaking() const
{
	return m_crimeCheckSneaking;
}
OwnershipRule SettingsCache::CrimeCheckNotSneaking() const
{
	return m_crimeCheckNotSneaking;
}
SpecialObjectHandling SettingsCache::PlayerBelongingsLoot() const
{
	return m_playerBelongingsLoot;
}
LockedContainerHandling SettingsCache::LockedChestLoot() const
{
	return m_lockedChestLoot;
}
SpecialObjectHandling SettingsCache::BossChestLoot() const
{
	return m_bossChestLoot;
}
SpecialObjectHandling SettingsCache::ValuableItemLoot() const
{
	return m_valuableItemLoot;
}
ContainerAnimationHandling SettingsCache::PlayContainerAnimation() const
{
	return m_playContainerAnimation;
}
QuestObjectHandling SettingsCache::QuestObjectLoot() const
{
	return m_questObjectLoot;
}
bool SettingsCache::EnableLootContainer() const
{
	return m_enableLootContainer;
}
bool SettingsCache::EnableHarvest() const
{
	return m_enableHarvest;
}
bool SettingsCache::LootAllowedItemsInSettlement() const
{
	return m_lootAllowedItemsInSettlement;
}
bool SettingsCache::LootAllowedItemsInPlayerHouse() const
{
	return m_lootAllowedItemsInPlayerHouse;
}
bool SettingsCache::UnknownIngredientLoot() const
{
	return m_unknownIngredientLoot;
}
bool SettingsCache::WhiteListTargetNotify() const
{
	return m_whiteListTargetNotify;
}
bool SettingsCache::ManualLootTargetNotify() const
{
	return m_manualLootTargetNotify;
}
PopulationCenterSize SettingsCache::PreventPopulationCenterLooting() const
{
	return m_preventPopulationCenterLooting;
}
int16_t SettingsCache::MaxMiningItems() const
{
	return m_maxMiningItems;
}
bool SettingsCache::MiningToolsRequired() const
{
	return m_miningToolsRequired;
}
bool SettingsCache::DisallowMiningIfSneaking() const
{
	return m_disallowMiningIfSneaking;
}

}

