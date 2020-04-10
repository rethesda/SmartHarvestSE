#include "PrecompiledHeaders.h"

#include "ExtraDataListHelper.h"
#include "CommonLibSSE/include/RE/ExtraEnchantment.h"
#include "CommonLibSSE/include/RE/ExtraAliasInstanceArray.h"

RE::EnchantmentItem * ExtraDataListHelper::GetEnchantment(void)
{
	if (!m_extraData)
		return false;

	RE::ExtraEnchantment* exEnchant = m_extraData->GetByType<RE::ExtraEnchantment>();
	return (exEnchant && exEnchant->enchantment) ? exEnchant->enchantment : nullptr;
}

bool ExtraDataListHelper::IsQuestObject(const bool requireFullQuestFlags)
{
	if (!m_extraData)
		return false;
#if 0
	// seems like this is incorrect, no data check
	if (!requireFullQuestFlags)
		return true;
#endif

	RE::ExtraAliasInstanceArray* exAliasArray = m_extraData->GetByType<RE::ExtraAliasInstanceArray>();
	if (!exAliasArray)
		return false;

	return std::find_if(exAliasArray->aliases.cbegin(), exAliasArray->aliases.cend(),
		[=](const RE::BGSRefAliasInstanceData* alias) -> bool {
			if (alias->alias->IsQuestObject() || (!requireFullQuestFlags && alias->quest)) {
#if _DEBUG
				_MESSAGE("Quest Item confirmed in alias for quest %0x08x, alias quest object %s",
					alias->quest ? alias->quest->formID : 0, alias->alias->IsQuestObject() ? "true" : "false");
#endif
				return true;
			}
			return false;
		}) != exAliasArray->aliases.cend();
}

