Scriptname SHSE_EventsAlias extends ReferenceAlias  

import SHSE_PluginProxy
import SHSE_MCM
GlobalVariable Property g_LootingEnabled Auto

int CACOModIndex
int CCORModIndex
MiscObject stalhrimOre
bool vanillaMakesNoise = False

int HearthfireExtendedModIndex
int MagicChestModIndex
int VidanisBagOfHoldingModIndex

bool scanActive = True
int pluginNonce
bool pluginDelayed
bool mcmOpen = False

int DefaultStrikesBeforeCollection

; handle auto mining edge case
Location Property CidhnaMineLocation Auto
Quest Property MS02 Auto
Quest Property DialogueCidhnaMine Auto
ObjectReference Property CidhnaMinePlayerBedREF Auto

; handle achievement for auto-mining
AchievementsScript property AchievementsQuest auto

Message property DisposeMsg auto
Container Property NameToDisplay auto

; INIFile::PrimaryType
int type_Common = 1
int type_Harvest = 2

; INIFile::SecondaryType
int itemSourceLoose = 2
int itemSourceNPC = 4

; object types must be in sync with the native DLL
int objType_Flora
int objType_Critter
int objType_Septim
int objType_Soulgem
int objType_Mine
int objType_Book
int objType_skillBookRead

Actor thisPlayer
bool logEvent

bool collectionsInUse

int resource_Ore
int resource_Geode
int resource_Volcanic
int resource_VolcanicDigSite

bool hasFossilMining = False
int NextDig
LeveledItem FOS_LItemFossilTierOneGeode
LeveledItem FOS_LItemFossilTierOneVolcanic
LeveledItem FOS_LItemFossilTierOneyum
LeveledItem FOS_LItemFossilTierOneVolcanicDigSite
LeveledItem FOS_LItemFossilTierTwoVolcanic

bool hasExtendedCutSaintsAndSeducers = False
bool hasCCSaintsAndSeducers = False
bool hasCCTheCause = False
ccBGSSSE001_DialogueDetectScript ccFishingDialogue = None
MiscObject sirenrootFlower = None
bool hasOrangeMoon = False

; supported Effect Shaders
EffectShader redShader          ; red
EffectShader flamesShader       ; flames
EffectShader purpleShader       ; purple
EffectShader copperShader       ; copper/bronze
EffectShader blueShader         ; blue
EffectShader goldShader         ; gold
EffectShader greenShader        ; green
EffectShader silverShader       ; silver
; Effect Shaders by category
EffectShader[] defaultCategoryShaders
EffectShader[] categoryShaders

; FormType from CommonLibSSE - this is core Game data, so invariant
int getType_kTree = 38
int getType_kFlora = 39

; legacy, unreliable
Formlist Property whitelist_form auto
Formlist Property blacklist_form auto
; replacement, easier to handle, stable
Form[] whiteListedForms
int whiteListSize
Form[] blackListedForms
int blackListSize

int location_type_whitelist
int location_type_blacklist
int list_type_transfer
int list_type_in_use_items
int pauseKeyCode
int whiteListKeyCode
int blackListKeyCode
bool keyHandlingActive

Form[] transferList
bool[] transferListInUse
string[] transferNames
int transferListSize

int maxMiningItems
bool miningToolsRequired
bool disallowMiningIfSneaking

int infiniteWeight

int glowReasonLockedContainer
int glowReasonBossContainer
int glowReasonQuestObject
int glowReasonCollectible
int glowReasonEnchantedItem
int glowReasonHighValue
int glowReasonPlayerProperty
int glowReasonSimpleTarget

Perk spergProspector

Function Prepare(Actor playerref, bool useLog)
    logEvent = useLog
    thisPlayer = playerref
    SetPlayer(playerRef)
    ;check for SPERG being active and set up the Prospector Perk to check
    int spergProspectorPerkID = 0x5cc21
    spergProspector = Game.GetFormFromFile(spergProspectorPerkID, "SPERG-SSE.esp") as Perk
    if !spergProspector || spergProspector.GetName() != "Prospector"
        AlwaysTrace("SPERG Prospector Perk resolve failed for " + PrintFormID(spergProspectorPerkID))
        spergProspector = None
    endIf

    RegisterForCrosshairRef()
EndFunction

; one-time migration logic for BlackList and WhiteList
Function CreateArraysFromFormLists()
    if !whiteListedForms
        whiteListSize = whitelist_form.GetSize()
        whiteListedForms = CreateArrayFromFormList(whitelist_form, whiteListSize)
    endIf
    if !blackListedForms
        blackListSize = blacklist_form.GetSize()
        blackListedForms = CreateArrayFromFormList(blacklist_form, blackListSize)
    endIf
EndFunction

Form[] Function CreateArrayFromFormList(FormList oldList, int oldSize)
    AlwaysTrace("Migrate FormList size(" + oldSize + ") to Form[]")
    Form[] newList = Utility.CreateFormArray(128)
    if oldSize > 0
        ; assume max size initially, resize if bad entries are found
        int validSize = 0
        int index = 0
        while index < oldSize
            newList[index] = oldList.GetAt(index)
            index += 1
        endWhile
    endIf
    return newList
EndFunction

Function CreateTransferListArrays()
    transferList = Utility.CreateFormArray(64, None)
    transferListInUse = Utility.CreateBoolArray(64, false)
    transferNames = Utility.CreateStringArray(64, "")
    transferListSize = 0
EndFunction

Function MigrateTransferListArrays(int oldLimit, int newLimit)
    if !transferList || transferList.Length != oldLimit || newLimit < oldLimit
        return
    endIf
    ; in-place Utility.ResizexxxArray does not work
    Form[] newList = Utility.CreateFormArray(newLimit)
    bool[] newListInUse = Utility.CreateBoolArray(newLimit)
    string[] newNames = Utility.CreateStringArray(newLimit)
    int index = 0
    while index < oldLimit
        newList[index] = transferList[index]
        newListInUse[index] = transferListInUse[index]
        newNames[index] = transferNames[index]
        ;DebugTrace("Source index " + index + "=" + transferList[index] + "/" + transferListInUse[index] + "/" + transferNames[index])
        ;DebugTrace("Temp   index " + index + "=" + newList[index] + "/" + newListInUse[index] + "/" + newNames[index])
        index += 1
    endWhile
    while index < newLimit
        newList[index] = None
        newListInUse[index] = False
        newNames[index] = ""
        ;DebugTrace("Temp   index " + index + "=" + newList[index] + "/" + newListInUse[index] + "/" + newNames[index])
        index += 1
    endWhile
    transferList = Utility.CreateFormArray(newLimit)
    transferListInUse = Utility.CreateBoolArray(newLimit)
    transferNames = Utility.CreateStringArray(newLimit)
    index = 0
    while index < newLimit
        ;DebugTrace("Initial index " + index + "=" + newList[index] + "/" + newListInUse[index] + "/" + newNames[index])
        transferList[index] = newList[index]
        transferListInUse[index] = False
        transferNames[index] = newNames[index]
        ;DebugTrace("Interim index " + index + "=" + newList[index] + "/" + newListInUse[index] + "/" + newNames[index])
        ;DebugTrace("Final   index " + index + "=" + transferList[index] + "/" + transferListInUse[index] + "/" + transferNames[index])
        index += 1
    endWhile
    AlwaysTrace("Migrated " + transferListSize + " Transfer List entries, limit " + oldLimit + " to new limit " + newLimit)
EndFunction

Function ResetExcessInventoryTargets(bool updated)
    int index = 0
    while index < 64
        ; reset transfer target - the old setting could be corrupt
        transferListInUse[index] = False
        index += 1
    endWhile
    if updated
        Debug.MessageBox(GetTranslation("$SHSE_MIGRATED_EXCESS_INVENTORY"))
    endIf
EndFunction

int Function GetWhiteListSize()
    return whiteListSize
EndFunction

int Function GetBlackListSize()
    return blackListSize
EndFunction

int Function GetTransferListSize()
    return transferListSize
EndFunction

Form[] Function GetWhiteList()
    return whiteListedForms
EndFunction

Form[] Function GetBlackList()
    return blackListedForms
EndFunction

Form[] Function GetTransferList()
    return transferList
EndFunction

string[] Function GetTransferNames()
    return transferNames
EndFunction

; merge FormList with plugin data
Function SyncList(int listNum, Form[] forms, int formCount)
    ; plugin resets to fixed baseline
    ResetList(listNum)
    ; ensure BlackList/WhiteList members are present in the plugin's list
    int index = 0
    while index < formCount
        Form nextEntry = forms[index]
        ; do not push empty entries to C++ for blacklist or whitelist.
        if nextEntry && (StringUtil.GetLength(GetNameForListForm(nextEntry)) > 0)
            AddEntryToList(listNum, nextEntry)
        else
            AlwaysTrace("Skipping sync for list #" + listNum + " entry " + nextEntry)
        endif
        index += 1
    endwhile
endFunction

; merge FormList with plugin data
Function SyncTransferList(Form[] forms, string[] names, int formCount)
    ; plugin resets to empty baseline
    ResetList(list_type_transfer)
    ; ensure BlackList/WhiteList members are present in the plugin's list
    int index = 0
    while index < formCount
        ; Transfer List is sparse. Include empty entries to keep plugin in sync.
        AddEntryToTransferList(forms[index], names[index])
        index += 1
    endwhile
endFunction

int Function UpdateListedForms(int totalEntries, Form[] myList, form[] updateList, bool[] flags, string trans)
    ; replace existing entries with valid Forms from MCM
    int index = 0
    int valid = 0
    while index < totalEntries
        if flags[index]
            myList[valid] = updateList[index]
            valid += 1
        else
            string translation = GetTranslation(trans)
            if (translation)
                translation = Replace(translation, "{ITEMNAME}", GetNameForListForm(updateList[index]))
                if (translation)
                    Debug.Notification(translation)
                endif
            endif
        endIf
        index += 1
    endWhile
    ;clear any removed entries
    index = valid
    while index < totalEntries
        myList[index] = None
        index += 1
    endWhile
    if valid != totalEntries
        AlwaysTrace("Updated Form[] size from (" + totalEntries + ") to (" + valid + ")")
    endIf
    return valid
endFunction

Function UpdateTransferListForms(int activeEntries, form[] updateList, bool[] updateInUse, int[] indices, string[] updateNames, bool[] flags, string trans)
    ; replace existing entries with valid Forms from MCM
    int index = 0
    int xrefIndex = 0   ; index of the passed container in the sparse list
    while index < activeEntries
        ; iterate blank entries
        while xrefIndex < indices[index]
            transferListInUse[xrefIndex] = False
            transferList[xrefIndex] = None
            transferNames[xrefIndex] = ""
            ;DebugTrace("Skip blank transfer list xref-index " + xrefIndex + " index " + index)
            xrefIndex += 1
        endWhile

        if flags[index]
            transferListInUse[xRefIndex] = updateInUse[index]
            transferList[xRefIndex] = updateList[index]
            transferNames[xRefIndex] = updateNames[index]
            ;DebugTrace("In-use transfer list xref-index " + xrefIndex + " index " + index + " " + transferNames[xRefIndex])
        else
            transferListInUse[xrefIndex] = False
            transferList[xrefIndex] = None
            transferNames[xrefIndex] = ""
            transferListSize -= 1
            ;DebugTrace("Unused transfer list xref-index " + xrefIndex + " index " + index)
        
            string translation = GetTranslation(trans)
            if (translation)
                translation = Replace(translation, "{ITEMNAME}", updateNames[index])
                if (translation)
                    Debug.Notification(translation)
                endif
            endif
        endIf
        xrefIndex += 1
        index += 1
    endWhile
endFunction

Function UpdateWhiteList(int totalEntries, Form[] updateList, bool[] flags, string trans)
    whiteListSize = UpdateListedForms(totalEntries, whiteListedForms, updateList, flags, trans)
EndFunction

Function UpdateBlackList(int totalEntries, Form[] updateList, bool[] flags, string trans)
    blackListSize = UpdateListedForms(totalEntries, blackListedForms, updateList, flags, trans)
EndFunction

Function UpdateTransferList(int activeEntries, bool[] updateInUse, Form[] updateList, int[] indices, string[] names, bool[] flags, string trans)
    UpdateTransferListForms(activeEntries, updateList, updateInUse, indices, names, flags, trans)
    SyncTransferList(transferList, transferNames, 64)
EndFunction

;push updated lists to plugin
Function SyncLists(bool reload, bool updateLists)
    if updateLists
        ; force plugin refresh of player's current worn and equipped items
        ResetList(list_type_in_use_items)
        SyncTransferList(transferList, transferNames, 64)
        SyncList(location_type_whitelist, whiteListedForms, whiteListSize)
        SyncList(location_type_blacklist, blackListedForms, blackListSize)
    endIf
    if reload
        ; reset UI State checking nonce in case saved game left us with a bum value
        pluginNonce = 0
        SetMCMState(false)
        mcmOpen = False
    endIf
    SyncDone(reload)
endFunction

int Function RemoveFormAtIndex(Form[] forms, int entries, int index)
    if index < entries
        AlwaysTrace("Removing " + forms[index] + ", entry " + (index+1) + " of " + entries)
        ; shuffle down entries above this one
        while index < entries - 1
            forms[index] = forms[index+1]
            index += 1
        endWhile
        ; clear prior final entry
        forms[entries - 1] = None
        return entries - 1
    endIf
    AlwaysTrace(index + " not valid for Form[]")
    return entries
endFunction

int Function ClearTransferListEntry(int listMax, int index)
    if index < listMax
        AlwaysTrace("Removing " + transferList[index] + ", entry " + index + " of " + listMax)
        transferList[index] = None
        transferNames[index] = ""
        transferListInUse[index] = False
        transferListSize -= 1
    else
        AlwaysTrace(index + " not a valid index for TransferList")
    endIf
endFunction

; manages FormList in VM - SyncLists pushes state to plugin once all local operations are complete
function ToggleStatusInBlackList(Form item)
    if !item
        return
    endif

    if !RemoveFromBlackList(item)
        AddToBlackList(item)
    endif
endFunction

function ToggleStatusInWhiteList(Form item)
    if !item
        return
    endif
    if !RemoveFromWhiteList(item)
        AddToWhiteList(item)
    endif
endFunction

; manages FormList in VM - SyncLists pushes state to plugin once all local operations are complete
function ToggleStatusInTransferList(string locationName, Form item)
    if !item
        return
    endif

    if RemoveFromTransferList(locationName, item) == 0
        AddToTransferList(locationName, item)
    endif
endFunction

function HandlePauseKeyPress(Form target)
    NameToDisplay.SetName(target.GetName())
    int ibutton = DisposeMsg.show()     ; allows user to dispose of all/excess selected items
    string result = ""
    if ibutton == 0 ; Sell All
        result = SellItem(target, False)
    elseif ibutton == 1 ; sell excess
        result = SellItem(target, True)
    elseif ibutton == 2 ; transfer all
        result = TransferItem(target, False)
    elseif ibutton == 3 ; transfer excess
        result = TransferItem(target, True)
    elseif ibutton == 4 ; delete all
        result = DeleteItem(target, False)
    elseif ibutton == 5 ; delete excess
        result = DeleteItem(target, True)
    elseif ibutton == 6 ; delete excess
        result = CheckItemAsExcess(target)
    endIf
    ; Cancel (7) or unknown option is a no-op
    if result != ""
        if ibutton < 6
            ; Poke InventoryMenu to update count        
            thisPlayer.RemoveItem(target, 0, True, None)
        endIf
        ; display diagnostic, error or action taken
        Debug.MessageBox(result)
    endIf
endFunction

function HandleWhiteListKeyPress(Form target)
    ; first remove from whitelist if present
    RemoveFromBlackList(target)
    ToggleStatusInWhiteList(target)
endFunction

bool function RemoveFromWhiteList(Form target)
    int match = whiteListedForms.find(target)
    if match != -1
        string translation = GetTranslation("$SHSE_WHITELIST_REMOVED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        whiteListSize = RemoveFormAtIndex(whiteListedForms, whiteListSize, match)
        AlwaysTrace(whiteListSize + " entries on WhiteList")
        return True
    endIf
    AlwaysTrace(target + " not found in WhiteList")
    return False
endFunction

function AddToWhiteList(Form target)
    ; do not add if empty or no name
    if !target || StringUtil.GetLength(GetNameForListForm(target)) == 0
        AlwaysTrace("Ignoring bad WhiteList Form (" + target + ")")
        return
    endIf
    if whiteListSize == 128
        string translation = GetTranslation("$SHSE_WHITELIST_FULL")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        return
    endIf
    if whiteListedForms.find(target) == -1
        string translation = GetTranslation("$SHSE_WHITELIST_ADDED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        whiteListedForms[whiteListSize] = target
        whiteListSize += 1
        AlwaysTrace(target + " added to WhiteList, size now " + whiteListSize)
    else
        AlwaysTrace(target + " already on WhiteList")
    endif
endFunction

function HandleBlackListKeyPress(Form target)
    ; first remove from whitelist if present
    RemoveFromWhiteList(target)
    ToggleStatusInBlackList(target)
endFunction

bool function RemoveFromBlackList(Form target)
    int match = blackListedForms.find(target)
    if match != -1
        string translation = GetTranslation("$SHSE_BLACKLIST_REMOVED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        blackListSize = RemoveFormAtIndex(blackListedForms, blackListSize, match)
        AlwaysTrace(blackListSize + " entries on BlackList")
        return True
    endIf
    AlwaysTrace(target + " not found in BlackList")
    return False
endFunction

function AddToBlackList(Form target)
    ; do not add if empty or no name
    if !target || StringUtil.GetLength(GetNameForListForm(target)) == 0
        AlwaysTrace("Ignoring bad BlackList Form (" + target + ")")
        return
    endIf
    if blackListSize == 128
        string translation = GetTranslation("$SHSE_BLACKLIST_FULL")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        return
    endIf
    if blackListedForms.find(target) == -1
        string translation = GetTranslation("$SHSE_BLACKLIST_ADDED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        blackListedForms[blackListSize] = target
        blackListSize += 1
        AlwaysTrace(target + " added to BlackList, size now " + blackListSize)
    else
        AlwaysTrace(target + " already on BlackList")
    endif
endFunction

int function RemoveFromTransferList(string locationName, Form target)
    int match = transferList.find(target)
    if match != -1
        if transferListInUse[match]
            string translation = GetTranslation("$SHSE_TRANSFERLIST_CANNOT_REMOVE_IN_USE")
            if (translation)
                string msg = Replace(translation, "{ITEMNAME}", locationName + "/" + GetNameForListForm(target))
                if (msg)
                    Debug.Notification(msg)
                endif
            endif
            return -1
        endif
        string translation = GetTranslation("$SHSE_TRANSFERLIST_REMOVED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", locationName + "/" + GetNameForListForm(target))
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        ClearTransferListEntry(64, match)
        AlwaysTrace(transferListSize + " entries on TransferList")
        return 1
    endIf
    AlwaysTrace(target + " not found in TransferList")
    return 0
endFunction

function AddToTransferList(string locationName, Form target)
    ; do not add if empty or no name
    string containerName = GetNameForListForm(target)
    if !target || StringUtil.GetLength(containerName) == 0
        AlwaysTrace("Skip bad Transfer List Entry (" + target + ")")
        return
    endIf
    string name = locationName + "/" + containerName
    if transferListSize == 64
        string translation = GetTranslation("$SHSE_TRANSFERLIST_FULL")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", name)
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        return
    endIf
    if transferList.find(target) == -1
        string translation = GetTranslation("$SHSE_TRANSFERLIST_ADDED")
        if (translation)
            string msg = Replace(translation, "{ITEMNAME}", name)
            if (msg)
                Debug.Notification(msg)
            endif
        endif
        ; find a free entry
        int index = 0
        while index < 64
            if transferList[index] == None
                transferList[index] = target
                transferListInUse[index] = False
                transferNames[index] = name
                transferListSize += 1
                AlwaysTrace(target + " added to TransferList at index " + index + ", size now " + transferListSize)
                return
            endif
            index += 1
        endWhile
    else
        AlwaysTrace(target + " already on TransferList")
    endif
endFunction

Function SetDefaultShaders()
    ; must line up with native GlowReason enum
    glowReasonLockedContainer = 0
    glowReasonBossContainer = 1
    glowReasonQuestObject = 2
    glowReasonCollectible = 3
    glowReasonHighValue = 4
    glowReasonEnchantedItem = 5
    glowReasonPlayerProperty = 6
    glowReasonSimpleTarget = 7

    ; must line up with shaders defined in ESP/ESM file
    redShader = Game.GetFormFromFile(0x80e, "SmartHarvestSE.esp") as EffectShader        ; red
    flamesShader = Game.GetFormFromFile(0x810, "SmartHarvestSE.esp") as EffectShader          ; flames
    purpleShader = Game.GetFormFromFile(0x80d, "SmartHarvestSE.esp") as EffectShader         ; purple
    copperShader = Game.GetFormFromFile(0x814, "SmartHarvestSE.esp") as EffectShader   ; copper
    goldShader = Game.GetFormFromFile(0x815, "SmartHarvestSE.esp") as EffectShader          ; gold
    blueShader = Game.GetFormFromFile(0x80b, "SmartHarvestSE.esp") as EffectShader     ; blue
    greenShader = Game.GetFormFromFile(0x80c, "SmartHarvestSE.esp") as EffectShader         ; green
    silverShader = Game.GetFormFromFile(0x813, "SmartHarvestSE.esp") as EffectShader        ; silver

    ; category default and current glow colour
    defaultCategoryShaders = new EffectShader[8]
    defaultCategoryShaders[glowReasonLockedContainer] = redShader
    defaultCategoryShaders[glowReasonBossContainer] = flamesShader
    defaultCategoryShaders[glowReasonQuestObject] = purpleShader
    defaultCategoryShaders[glowReasonCollectible] = copperShader
    defaultCategoryShaders[glowReasonHighValue] = goldShader
    defaultCategoryShaders[glowReasonEnchantedItem] = blueShader
    defaultCategoryShaders[glowReasonPlayerProperty] = greenShader
    defaultCategoryShaders[glowReasonSimpleTarget] = silverShader

    categoryShaders = new EffectShader[8]
    int index = 0
    while index < categoryShaders.length
        categoryShaders[index] = defaultCategoryShaders[index]
        index = index + 1
    endWhile
EndFunction

Function SyncShaders(Int[] colours)
    int index = 0
    while index < colours.length
        categoryShaders[index] = defaultCategoryShaders[colours[index]]
        SyncShader(index, categoryShaders[index])
        index = index + 1
    endWhile
EndFunction

Function SyncVeinResourceTypes()
    resource_Ore = GetResourceTypeByName("Ore")
    resource_Geode = GetResourceTypeByName("Geode")
    resource_Volcanic = GetResourceTypeByName("Volcanic")
    resource_VolcanicDigSite = GetResourceTypeByName("VolcanicDigSite")
EndFunction

; must line up with enumerations from C++
Function SyncUpdatedNativeDataTypes()
    objType_Flora = GetObjectTypeByName("flora")
    objType_Critter = GetObjectTypeByName("critter")
    objType_Septim = GetObjectTypeByName("septims")
    objType_Soulgem = GetObjectTypeByName("soulgem")
    objType_Mine = GetObjectTypeByName("oreVein")
    objType_Book = GetObjectTypeByName("book")
    objType_skillBookRead = GetObjectTypeByName("skillbookread")

    SyncVeinResourceTypes()

    location_type_whitelist = 1
    location_type_blacklist = 2
    list_type_transfer = 3
    list_type_in_use_items = 4

    infiniteWeight = 100000
endFunction

Function ResetCollections()
    ;prepare for collection management, if configured
    collectionsInUse = CollectionsInUse()
    if !collectionsInUse
        return
    endIf
    ;DebugTrace("eventScript.ResetCollections")
EndFunction

Function ApplySetting()
    ;DebugTrace("eventScript ApplySetting start")
    UnregisterForAllKeys()
    UnregisterForMenu("Loading Menu")

    if pauseKeyCode != 0
         RegisterForKey(pauseKeyCode)
    endif
    if whiteListKeyCode != 0
        RegisterForKey(whiteListKeyCode)
    endif
    if blackListKeyCode != 0
        RegisterForKey(blackListKeyCode)
    endif

    utility.waitMenumode(0.1)
    RegisterForMenu("Loading Menu")
    ;DebugTrace("eventScript ApplySetting finished")
endFunction

string Function sif (bool cc, string aa, string bb) global
    string result
    if (cc)
        result = aa
    else
        result = bb
    endif
    return result
endFunction

Function PushScanActive()
    SyncScanActive(scanActive)
    if scanActive
        Debug.Notification(Replace(GetTranslation("$SHSE_UNPAUSED"), "{VERSION}", GetPluginVersion()))
    else
        Debug.Notification(Replace(GetTranslation("$SHSE_PAUSED"), "{VERSION}", GetPluginVersion()))
    endif
EndFunction

Function SyncWhiteListKey(int keyCode)
    whiteListKeyCode = keyCode
EndFunction

Function SyncBlackListKey(int keyCode)
    blackListKeyCode = keyCode
EndFunction

Function SyncPauseKey(int keyCode)
    pauseKeyCode = keyCode
EndFunction

; hotkey changes sense of looting. Use of MCM/new character/game reload resets this to whatever's
; implied by current settings
function Pause()
    string s_enableStr = none
    scanActive = !scanActive
    PushScanActive()
endFunction

; BlackList/WhiteList hotkeys
Function HandleCrosshairItemHotKey(ObjectReference targetedRefr, bool isWhiteKey, Float holdTime)
    ; check for long press
    if holdTime > 1.5
        if isWhiteKey
            if targetedRefr.GetBaseObject() as Container
                ProcessContainerCollectibles(targetedRefr)
            elseif targetedRefr.GetBaseObject() as Book
                ; special-case to force-harvest Quest Targets
                TryForceHarvest(targetedRefr)
            else
                Debug.Notification("$SHSE_HOTKEY_NOT_A_CONTAINER_OR_FORCE_HARVEST")
            endif
        else ; BlackList Key
            ; object lootability introspection
            CheckLootable(targetedRefr)
        endIf
    else
        ; regular press. Does nothing unless this is a non-generated Dead Body or Container, or a Lootable Object
        bool valid = False
        Actor refrActor = targetedRefr as Actor
        Container refrContainer = targetedRefr.GetBaseObject() as Container
        if refrActor || refrContainer
            valid = !IsDynamic(targetedRefr) && ((refrActor && refrActor.IsDead()) || refrContainer)
            if valid
                ; blacklist or un-blacklist the REFR, not the Base, to avoid blocking other REFRs with same Base
                if isWhiteKey
                    RemoveFromBlackList(targetedRefr)
                else ; BlackList Key
                    AddToBlackList(targetedRefr)
                EndIf
            endif
        elseif IsLootableObject(targetedRefr)
            ; open world blacklist or whitelist for item
            valid = True
            if isWhiteKey
                HandleWhiteListKeyPress(targetedRefr.GetBaseObject())
            else ; blacklist key
                HandleBlackListKeyPress(targetedRefr.GetBaseObject())
            endif
        endif
        if valid
            SyncLists(false, true)    ; not a reload
        else
            Debug.Notification("$SHSE_HOTKEY_NOT_VALID_FOR_LISTS")
        endIf
    endIf
EndFunction

; Pause hotkey on crosshair item indicates user is trying to set or unset a Loot Transfer Target
Function HandleCrosshairPauseHotKey(ObjectReference targetedRefr)
    ; Does nothing unless this is a Container to which we can safely send loot
    ; check for REFR that encapsulates a valid linked Container
    bool linkedChest = False
    bool knownGood = False
    ObjectReference refrToStore = targetedRefr
    if targetedRefr as ActivateLinkedChestDummyScript != None
        linkedChest = True
    elseif (MagicChestModIndex != 255) && (targetedRefr as _Skyrim_SE_Nexus_Script != None)
        knownGood = True
        linkedChest = True
    elseIf (VidanisBagOfHoldingModIndex != 255) && (targetedRefr as aaaMRbohArmScript != None)
        knownGood = True
        refrToStore = (targetedRefr as aaaMRbohArmScript).aaaMRbohContREF
    endIf
    ;DebugTrace("REFR " + refrToStore + ", linked container ? " + linkedChest + ", known good ? " + knownGood)
    string locationName = ValidTransferTargetLocation(refrToStore, linkedChest, knownGood)
    if locationName != ""
        ; add or remove the REFR, not the Base, to avoid blocking other REFRs with same Base
        ToggleStatusInTransferList(locationName, refrToStore)
        SyncTransferList(transferList, transferNames, 64)
    else
        Debug.Notification("$SHSE_HOTKEY_NOT_VALID_FOR_TRANSFERLIST")
    endIf
EndFunction

Event OnKeyUp(Int keyCode, Float holdTime)
    if (UI.IsTextInputEnabled())
        return
    endif
    ; only handle one at a time, if player spams the keyboard results will be confusing
    if keyHandlingActive
        return
    endif
    keyHandlingActive = true
    if (!Utility.IsInMenumode())
        ; handle hotkey actions for crosshair in reference
        ObjectReference targetedRefr = Game.GetCurrentCrosshairRef()
        if keyCode == pauseKeyCode
            if holdTime > 1.5
                ; add Container to TargetList requires long press
                if targetedRefr
                    HandleCrosshairPauseHotKey(targetedRefr)
                    keyHandlingActive = false
                    return
                endIf
                ; trigger shader test on really long press
                ToggleCalibration(holdTime > 5.0)
            else
                Pause()
            endif
        elseif keyCode == whiteListKeyCode || keyCode == blackListKeyCode
            if targetedRefr
                if mcmOpen
                    AlwaysTrace("MCM Open, ignore crosshair blacklist/whitelist hotkey")
                else
                    HandleCrosshairItemHotKey(targetedRefr, keyCode == whiteListKeyCode, holdTime)
                endif
                keyHandlingActive = false
                return
            endIf

            ; Location/cell blacklist whitelist toggle in worldspace
            Form place = GetPlayerPlace()
            if (!place)
                if keyCode == whiteListKeyCode
                    Debug.Notification(GetTranslation("$SHSE_WHITELIST_FORM_ERROR"))
                else
                    Debug.Notification(GetTranslation("$SHSE_BLACKLIST_FORM_ERROR"))
                endIf
                keyHandlingActive = false
                return
            endif
            if mcmOpen
                AlwaysTrace("MCM Open, ignore location blacklist/whitelist hotkey")
                keyHandlingActive = false
                return
            else
                if keyCode == whiteListKeyCode
                    HandleWhiteListKeyPress(place)
                else ; blacklist key
                    HandleBlackListKeyPress(place)
                endif
                SyncLists(false, true)    ; not a reload
            endif
        endif
    ; menu open - only actionable on our blacklist/whitelist keys
    elseif keyCode == whiteListKeyCode || keyCode == blackListKeyCode || keyCode == pauseKeyCode
        string s_menuName = none
        if (UI.IsMenuOpen("InventoryMenu"))
            s_menuName = "InventoryMenu"
        elseif (UI.IsMenuOpen("ContainerMenu"))
            s_menuName = "ContainerMenu"
        endif
        
        if (s_menuName == "ContainerMenu" || s_menuName == "InventoryMenu")

            Form itemForm = GetSelectedItemForm(s_menuName)
            if !itemForm
                string msg
                if keyCode == whiteListKeyCode
                    msg = "$SHSE_WHITELIST_FORM_ERROR"
                else
                    msg = "$SHSE_BLACKLIST_FORM_ERROR"
                endIf
                Debug.Notification(msg)
                keyHandlingActive = false
                return
            endif

            if keyCode == pauseKeyCode
                HandlePauseKeyPress(itemForm)
            else
                if IsQuestTarget(itemForm)
                    string msg
                    if keyCode == whiteListKeyCode
                        msg = "$SHSE_WHITELIST_QUEST_TARGET"
                    else
                        msg = "$SHSE_BLACKLIST_QUEST_TARGET"
                    endIf
                    Debug.Notification(msg)
                    keyHandlingActive = false
                    return
                endif
                if keyCode == whiteListKeyCode
                    HandleWhiteListKeyPress(itemForm)
                else ; blacklist key
                    HandleBlackListKeyPress(itemForm)
                endif
                SyncLists(false, true)    ; not a reload
            endIf
        endif
    endif
    keyHandlingActive = false
endEvent

function updateMaxMiningItems(int maxItems)
    ;DebugTrace("maxMiningItems -> " + maxItems)
    maxMiningItems = maxItems
endFunction

function updateMiningToolsRequired(bool toolsRequired)
    ;DebugTrace("miningToolsRequired -> " + toolsRequired)
    miningToolsRequired = toolsRequired
endFunction

function updateDisallowMiningIfSneaking(bool noSneakyMining)
    ;DebugTrace("disallowMiningIfSneaking -> " + noSneakyMining)
    disallowMiningIfSneaking = noSneakyMining
endFunction

bool Function IsBookObject(int type)
    return type >= objType_Book && type <= objType_skillBookRead
endFunction

bool Function CanMine(MineOreScript handler, int available)
    ; 'available' is set to -1 before the vein is initialized - after we call giveOre the amount received is
    ; in ResourceCount and the remaining amount in ResourceCountCurrent 
    ;DebugTrace("Available ore: " + available)
    if available == 0
        PeriodicReminder(handler.DepletedMessage)
        return False
    endif
    ; Cidhna Mine special case
    If thisPlayer.GetCurrentLocation() == CidhnaMineLocation && MS02.ISRunning() == False
        ;DebugTrace(handler + " Player is in Cidhna Mine, activate the bed to serve time")
        if CidhnaMinePlayerBedREF.Activate(thisPlayer)
            DialogueCidhnaMine.SetStage(45)
        else
            AlwaysTrace("CanMine: Activate failed for " + CidhnaMinePlayerBedREF)
        endIf
        return False
    EndIf
    return True
endFunction

bool Function LacksRequiredTools(MineOreScript handler)
    ; Vanilla Mining handling for player
    ; We don't recheck on each attack (OnHit, normally sent from FURN record)
    ; Nor do we check that a correct item is being used, as in Advanced Mining: only check player has tool in inventory
    ;DebugTrace("Tools required: " + miningToolsRequired + ", PlayerHasTools:" + handler.playerHasTools())
    if miningToolsRequired && !handler.playerHasTools()
        PeriodicReminder(handler.FailureMessage)
        return True
    endif
    return False
endFunction

bool Function CanMineCACO(CACO_MineOreScript handler, int available)
    ; 'available' is set to -1 before the vein is initialized - after we call giveOre the amount received is
    ; in ResourceCount and the remaining amount in ResourceCountCurrent 
    if available == 0
        PeriodicReminder(handler.DepletedMessage)
        return False
    endif
    ; duplicate vanilla Cidhna Mine processing
    If thisPlayer.GetCurrentLocation() == CidhnaMineLocation && MS02.ISRunning() == False
        ;DebugTrace(self + "Player is in Cidhna Mine, activate the bed to serve time")
        if CidhnaMinePlayerBedREF.Activate(thisPlayer)
            DialogueCidhnaMine.SetStage(45)
        else
            AlwaysTrace("CanMineCACO: Activate failed for " + CidhnaMinePlayerBedREF)
        endIf
        return False
    EndIf
    return True
endFunction

bool Function LacksRequiredToolsCACO(CACO_MineOreScript handler)
    ; CACO handling for player
    ; We don't recheck each attack since that processing is bypassed
    ; Nor do we check that a correct item is being used, per Advanced Mining - just that player has one in inventory
    ;DebugTrace("CACO tools required: " + miningToolsRequired + ", PlayerHasTools:" + handler.playerHasTools())
    if miningToolsRequired && !handler.playerHasTools()
        PeriodicReminder(handler.FailureMessage)
        return True
    endif
    return False
endFunction

bool Function LacksRequiredToolsFossils(FOS_DigsiteScript handler)
    ; Fossil Mining handling for player
    ; We don't recheck each attack since that processing is bypassed
    ; Nor do we check that a correct item is being used, per Advanced Mining - just that player has one in inventory
    ;DebugTrace("Fossil tools required: " + miningToolsRequired + ", PlayerHasTools:" + thisPlayer.GetItemCount(handler.mineOreToolsList))
    if miningToolsRequired && !thisPlayer.GetItemCount(handler.mineOreToolsList)
        PeriodicReminderString("You lack a pick")
        return True
    endif
    return False
endFunction

; brute force mineable resource gathering to bypass immersive but slow MineOreScript/Furniture handshaking and animations
Event OnMining(ObjectReference akMineable, int resourceType, bool manualLootNotify, bool isFirehose)
    if logEvent
        DebugTrace("OnMining: " + akMineable.GetDisplayName() + "RefID(" +  akMineable.GetFormID() + ")  BaseID(" + akMineable.GetBaseObject().GetFormID() + ")" ) 
        DebugTrace("resource type: " + resourceType + ", notify for manual loot: " + manualLootNotify)
    endIf
    int miningStrikes = 0
    int targetResourceTotal = 0
    int strikesToCollect = 0
    MineOreScript oreScript = akMineable as MineOreScript
    int FOSStrikesBeforeFossil
    bool handled = false
    int initialOreCount = 0
    if (oreScript)
        ; This works for Vanilla and CCOR.
        ; Other versions of oreScript need research. Advanced Mining is not compatible.
        if logEvent
            DebugTrace("Detected ore vein")
        endIf            
        initialOreCount = thisPlayer.GetItemCount(oreScript.ore)

        int mined = 0
        bool useSperg = spergProspector && thisPlayer.HasPerk(spergProspector)
        if useSperg
            PrepareSPERGMining()
        endif
        if oreScript.ResourceCountTotal == -1
            ;DebugTrace("Vein not yet initialized, start mining")
            oreScript.ResourceCountCurrent = oreScript.ResourceCountTotal
        endIf            
        targetResourceTotal = oreScript.ResourceCountTotal
        ; esoteric CCOR special case
        if stalhrimOre == oreScript.ore
            strikesToCollect = 2 * DefaultStrikesBeforeCollection
        else
            strikesToCollect = DefaultStrikesBeforeCollection
        endif
        int available = oreScript.ResourceCountCurrent
        ;DebugTrace("Vein has ore available: " + available)

        ; 'available' is set to -1 before the vein is initialized - after we call giveOre the amount received is
        ; in ResourceCount and the remaining amount in ResourceCountCurrent 
        bool firstTime = True
        bool toolsFailed = LacksRequiredTools(oreScript)
        if toolsFailed
            ; allow retry, player might acquire tools in the interim
            UnblockMineable(akMineable)
        else
            while (mined < maxMiningItems) && OKToScan() && CanMine(oreScript, available)
                ; Vanilla resource retrieval.
                if logEvent
                    if CCORModIndex != 255
                        DebugTrace("Trigger CCOR Mining")
                    else
                        DebugTrace("Trigger Vanilla Mining")
                    endif
                endIf       
                if firstTime
                    if CCORModIndex != 255 && ((Game.GetFormFromFile(0x01CC0508, "Update.esm") As GlobalVariable).GetValue() As Int) == 1 ;MiningMakesNoise_CCO	
                        oreScript.CreateDetectionEvent(thisPlayer, 250)		;MINING MAKE NOISE by Kryptopyr	
                    endif
                        firstTime = False
                endif
            
                ; Vanilla and CCOR giveOre() also handle distribution of gems
                oreScript.giveOre()

                mined = thisPlayer.GetItemCount(oreScript.Ore) - initialOreCount;
                available = oreScript.ResourceCountCurrent
                if logEvent
                    DebugTrace("Ore amount so far: " + mined + ", max: " + maxMiningItems + ", available: " + available)
                endIf            
                miningStrikes += 1
            endwhile
        endIf
        if !OKToScan()
            AlwaysTrace("UI open : oreScript mining interrupted, " + mined + " obtained")
        endIf
        if logEvent
            DebugTrace("Ore harvested amount: " + mined + ", remaining: " + available)
        endIf
        if useSperg
            PostprocessSPERGMining()
        endif
        FOSStrikesBeforeFossil = 6
        handled = true
    endif
    ; CACO provides its own mining script, unfortunately not derived from baseline though largely identical
    if !handled && (CACOModIndex != 255)
        CACO_MineOreScript cacoMinable = akMineable as CACO_MineOreScript
        if (cacoMinable)
            if logEvent
                DebugTrace("Detected CACO ore vein")
            endIf
            ; we must call giveOre before we can trust ResourceCountCurrent: in CACO, value depends on the resource type
            int mined = 0
            int available = cacoMinable.ResourceCountCurrent
            if available != -1
                targetResourceTotal = cacoMinable.ResourceCountTotal
                strikesToCollect = cacoMinable.StrikesBeforeCollection
                available = cacoMinable.ResourceCountCurrent
                ;DebugTrace("CACO ore vein has ore available: " + available)
            else
                ;DebugTrace("CACO ore vein not set up yet, need to call giveOre")
            endif
    
            ; 'available' is set to -1 before the vein is initialized - after we call giveOre the amount received is
            ; in ResourceCount and the remaining amount in ResourceCountCurrent 
            bool firstTime = True
            bool toolsFailed = LacksRequiredToolsCACO(cacoMinable)
            if toolsFailed
                ; allow retry, player might acquire tools in the interim
                UnblockMineable(akMineable)
            else
                while (mined < maxMiningItems) && OKToScan() && CanMineCACO(cacoMinable, available) && !toolsFailed
                    if logEvent
                        DebugTrace("Trigger CACO ore harvesting")
                    endIf            
                    if firstTime
                        if cacoMinable.MiningMakesNoise_CCO.GetValue() == 1
                            cacoMinable.CreateDetectionEvent(thisPlayer, 250)   ;MINING MAKE NOISE by Kryptopyr	
                        endif
                        firstTime = False
                    endif
                    cacoMinable.giveOre()
                    mined = thisPlayer.GetItemCount(cacoMinable.Ore) - initialOreCount;
                    ; script properties are trusted now 
                    available = cacoMinable.ResourceCountCurrent
                    targetResourceTotal = cacoMinable.ResourceCountTotal
                    strikesToCollect = cacoMinable.StrikesBeforeCollection
                    if logEvent
                        DebugTrace("CACO ore vein amount so far: " + mined + ", max: " + maxMiningItems + ", available: " + available)
                    endIf           
                    miningStrikes += 1
                endwhile
            endIf
            if !OKToScan()
                AlwaysTrace("UI open : CACO_MineOreScript mining interrupted, " + mined + " obtained")
            endIf
            if logEvent
                DebugTrace("CACO ore vein harvested amount: " + mined + ", remaining: " + available)
            endIf            
            handled = true
        endif
    endif
    ; update achievement progress if we mined anything
    if miningStrikes > 0
        AchievementsQuest.incHardworker(2)
    endif

    if !handled && hasFossilMining
        if logEvent
            DebugTrace("Check for Fossil Mining Dig Site")
        endIf            
        FOS_DigsiteScript FOSMinable = akMineable as FOS_DigsiteScript
        if (FOSMinable)
            if logEvent
                DebugTrace("Process Fossil Mining Dig Site")
            endIf            
            ; housekeeping
            float now = Utility.GetCurrentGameTime()
            if FOSMinable.GetLinkedRef().IsDisabled() && now >= NextDig
                FOSMinable.GetLinkedRef().Enable()
            endif
            
            ; REFR will be blocked ater this call, until we leave the cell
            ; FOS script enables the FURN when we first enter the cell, provided mining is legal
            ; If we re-enter the cell we will check again but not be able to mine
            bool toolsFailed = LacksRequiredToolsFossils(FOSMinable)
            if toolsFailed
                ; allow retry, player might acquire tools in the interim
                UnblockMineable(akMineable)
            elseif now >= NextDig
                NextDig = (now + 30) as Int
                thisPlayer.AddItem(FOS_LItemFossilTierOneVolcanicDigSite, 1)
                thisPlayer.AddItem(FOS_LItemFossilTierTwoVolcanic, 1)
                PeriodicReminderString("Dig site is exhausted")
                FOSMinable.GetLinkedRef().Disable() 
            else
                PeriodicReminderString("Dig site is exhausted, check back at a later time.")    
            endif
            handled = true
        endif
    endif

    if isFirehose
        ; no-op

    elseif (miningStrikes > 0 && hasFossilMining && resourceType != resource_VolcanicDigSite)
        ; Fossil Mining Drop Logic from oreVein per Fos_AttackMineAlias.psc, bypassing the FURN.
        ; Excludes Hearthfire house materials (by construction) to mimic FOS_IgnoreList filtering.
        ; Excludes Fossil Mining Dig Sites, processed in full above
        ;randomize drop of fossil based on number of strikes and vein characteristics
        FOSStrikesBeforeFossil = strikesToCollect * targetResourceTotal
        int dropFactor = Utility.RandomInt(1, FOSStrikesBeforeFossil)
        if logEvent
            DebugTrace("Fossil Mining: strikes = " + miningStrikes + ", required for drop = " + FOSStrikesBeforeFossil)
        endIf            
        if (dropFactor <= miningStrikes)
            if logEvent
                DebugTrace("Fossil Mining: provide loot!")
            endIf            
            if (resourceType == resource_Geode)
                thisPlayer.AddItem(FOS_LItemFossilTierOneGeode, 1)
            Elseif (resourceType == resource_Volcanic)
                thisPlayer.AddItem(FOS_LItemFossilTierOneVolcanic, 1)
            Elseif (resourceType == resource_Ore)
                thisPlayer.AddItem(FOS_LItemFossilTierOneyum, 1)
            Endif
        Endif
    Endif

    if !handled && manualLootNotify
        ; unrecognized 'Mine' verb target - print message for 'nearby manual lootable' if configured to do so
        NotifyManualLootItem(akMineable)
    endif
EndEvent

int Function SyntheticFloraActivateCount(ObjectReference target)
    if HearthfireExtendedModIndex != 255 && target as KmodApiaryScript
        return 5
    endIf
    return 1
EndFunction

; don't worry about interrupting Fishing, the minigame won't yield this type of object
Event OnHarvestSyntheticFlora(ObjectReference akTarget, Form itemForm, string baseName, int itemType, int count, bool silent, bool collectible, bool isWhitelisted)
    bool notify = false
    ; capture values now, dynamic REFRs can become invalid before we need them
    int refrID = akTarget.GetFormID()
    Form baseForm = akTarget.GetBaseObject()
    int baseID = baseForm.GetFormID()
    bool activated = False

    ;DebugTrace("OnHarvestSyntheticFlora: target " + akTarget + ", base " + itemForm + ", item type: " + itemType + ", do not notify: " + silent)
    if !akTarget.IsActivationBlocked() && IsInHarvestableState(akTarget)
        int activations = SyntheticFloraActivateCount(akTarget)
        activated = ActivateItem1(akTarget, thisPlayer, true, activations)
        if activated
            notify = !silent
            if activations == 1 && count >= 2
                ; work round for ObjectReference.Activate() known issue
                ; https://www.creationkit.com/fallout4/index.php?title=Activate_-_ObjectReference
                int toGet = count - 1
                thisPlayer.AddItem(itemForm, toGet, true)
                ;DebugTrace("Add extra count " + toGet + " of " + itemForm)
            endIf
            SetHarvested(akTarget)
            ;DebugTrace("OnHarvestSyntheticFlora:Activated:" + akTarget)
        else
            AlwaysTrace("OnHarvestSyntheticFlora: Activate failed for " + akTarget)
        endif
    endif
    NotifyActivated(itemForm, itemType, collectible, refrID, baseID, notify, baseName, count, activated, silent, isWhitelisted)
endEvent

bool Function CanHarvestCritter(ObjectReference target)
    if target as FXfakeCritterScript
        return True
    endif
    if target as critter
        critterFish fishCritter = target as critterFish
        if fishCritter && ccFishingDialogue
            ; Do not screw up CC Fishing - main Fishing script keeps DialogueDetect active only when player is fishing
            ;DebugTrace("CanHarvestCritter: ccFishingDialogue.dialogueDetectEnabled=" + ccFishingDialogue.dialogueDetectEnabled.GetValueInt())
            return ccFishingDialogue.dialogueDetectEnabled.GetValueInt() == 0
        else
            return True
        endif
    endif
    AlwaysTrace("CanHarvestCritter called for invalid target " + target + ", base " + target.GetBaseObject())
    return False
endFunction

; Don't interfere with the CC Fishing dialogue
bool Function CanHarvest(int objectType)
    if ccFishingDialogue
        ; Do not screw up CC Fishing - main Fishing script keeps DialogueDetect active only when player is fishing
        ;DebugTrace("CanHarvest: ccFishingDialogue.dialogueDetectEnabled=" + ccFishingDialogue.dialogueDetectEnabled.GetValueInt())
        return ccFishingDialogue.dialogueDetectEnabled.GetValueInt() == 0
    endif
    return True
endFunction

Event OnHarvestCritter(ObjectReference akTarget, Form itemForm, string baseName, int itemType, int count, bool silent, bool collectible, bool isWhitelisted)
    bool notify = false
    ; capture values now, dynamic REFRs can become invalid before we need them
    int refrID = akTarget.GetFormID()
    Form baseForm = akTarget.GetBaseObject()
    int baseID = baseForm.GetFormID()
    bool activated = False

    ;DebugTrace("OnHarvestCritter: target " + akTarget + ", base " + itemForm + ", item type: " + itemType + ", do not notify: " + silent)
    if !akTarget.IsActivationBlocked() && CanHarvestCritter(akTarget)
        activated = ActivateItem2(akTarget, thisPlayer, silent, 1)
        if !activated
            AlwaysTrace("OnHarvestCritter: Activate failed for " + akTarget)
        endIf
        ;DebugTrace("OnHarvestCritter:Activated:" + akTarget)
    endif
    NotifyActivated(itemForm, itemType, collectible, refrID, baseID, notify, baseName, count, activated, silent, isWhitelisted)
endEvent

Event OnHarvest(ObjectReference akTarget, Form itemForm, string baseName, int itemType, int count, bool silent, bool collectible, float ingredientCount, bool isWhitelisted)
    bool notify = false
    ; capture values now, dynamic REFRs can become invalid before we need them
    int refrID = akTarget.GetFormID()
    Form baseForm = akTarget.GetBaseObject()
    int baseID = baseForm.GetFormID()
    bool activated = False

    ;DebugTrace("OnHarvest: target " + akTarget + ", base " + itemForm + ", item type: " + itemType + ", do not notify: " + silent)
    if (IsBookObject(itemType))
        activated = True;
        thisPlayer.AddItem(akTarget, count, true)
        notify = !silent
    elseif (itemType == objType_Soulgem && akTarget.GetLinkedRef(None))
        ; Harvest trapped SoulGem only after deactivation - no-op otherwise
        TrapSoulGemController myTrap = akTarget as TrapSoulGemController
        if myTrap
            string baseState = akTarget.GetLinkedRef(None).getState()
            if logEvent
                DebugTrace("Trapped soulgem " + akTarget + ", state " + myTrap.getState() + ", linked to " + akTarget.GetLinkedRef(None) + ", state " + baseState) 
            endIf
            if myTrap.getState() == "disarmed" && (baseState == "disarmed" || baseState == "idle")
                activated = ActivateItem3(akTarget, thisPlayer, true, 1)
                if activated
                    notify = !silent
                else
                    AlwaysTrace("OnHarvest: Activate failed for trapped soulgem" + akTarget)
                endIf
            endIf
        endIf
    elseif !akTarget.IsActivationBlocked() && CanHarvest(itemType)
        if itemType == objType_Septim && baseForm.GetType() == getType_kFlora
            activated = ActivateItem4(akTarget, thisPlayer, silent, 1)
            if !activated
                AlwaysTrace("OnHarvest: Activate failed for Flora" + akTarget)
            endIf

        elseif baseForm.GetType() == getType_kFlora || baseForm.GetType() == getType_kTree
            ; "Flora" or "Tree" Producer REFRs cannot be identified by item type
            ;DebugTrace("Player has ingredient count " + ingredientCount)
            bool suppressMessage = silent || ingredientCount as int > 1
            ;DebugTrace("Flora/Tree original base form " + itemForm.GetName())
            activated = ActivateItem5(akTarget, thisPlayer, suppressMessage, 1)
            if activated
                ;we must send the message if required default would have been incorrect
                notify = !silent && ingredientCount as int > 1
                count = count * ingredientCount as int
            else
                AlwaysTrace("OnHarvest: Activate failed for Tree/Flora" + akTarget)
            endif
        else
            activated = ActivateItem6(akTarget, thisPlayer, true, 1)
            if activated
                notify = !silent
                if count >= 2
                    ; work round for ObjectReference.Activate() known issue
                    ; https://www.creationkit.com/fallout4/index.php?title=Activate_-_ObjectReference
                    int toGet = count - 1
                    thisPlayer.AddItem(itemForm, toGet, true)
                    ;DebugTrace("Add extra count " + toGet + " of " + itemForm)
                endIf
            else
                AlwaysTrace("OnHarvest: Activate failed for " + akTarget)
            endif
        endif
        ;DebugTrace("OnHarvest:Activated:" + akTarget + " = " + activated)
    endif
    NotifyActivated(itemForm, itemType, collectible, refrID, baseID, notify, baseName, count, activated, silent, isWhitelisted)
endEvent

Event OnGetProducerLootable(ObjectReference akTarget)
    Form baseForm = akTarget.GetBaseObject()
    AlwaysTrace("OnGetProducerLootable: REFR=" +  akTarget + ", Base=" + baseForm )
    ; Vanilla ACTI that are categorized as Flora but harvested like critters via scripted ACTI
    NirnrootACTIVATORScript nirnrootACTI = akTarget as NirnrootACTIVATORScript
    if nirnrootACTI
        SetLootableForProducer(baseForm, nirnrootACTI.nirnroot)
        return
    endif
    DLC1TrapPoisonBloom poisonBloom = akTarget as DLC1TrapPoisonBloom
    if poisonBloom
        SetLootableForProducer(baseForm, poisonBloom.myIngredient)
        return
    endif
    ; handle Saints and Seducers
    if hasCCSaintsAndSeducers
        ; This can be LVLI (CACO-patched) or INGR (unpatched), compilation of cast appears to depend on what script is found by Paprus Compiler
        ccBGSSSE025_HarvestableActivator saintsFlora = akTarget as ccBGSSSE025_HarvestableActivator
        if saintsFlora
            ; Behaves differently if Rare Curios is active
            if saintsFlora.useRareCuriosItem as Bool && saintsFlora.isRareCuriosLoaded.GetValueInt() == 1
                SetLootableForProducer(baseForm, saintsFlora.leveledRareCuriosItem as Form)
            else
                SetLootableForProducer(baseForm, saintsFlora.itemToHarvest as Form)
            endif
            return
        endif
    endif
    ; handle Extended Cut - Saints and Seducers
    if hasExtendedCutSaintsAndSeducers
        EC_HarvestTreeofShades ecssFlora = akTarget as EC_HarvestTreeofShades
        if ecssFlora
            SetLootableForProducer(baseForm, ecssFlora.ccBGSSSE019_BranchOfTreeOfShades as Form)
            return
        endif
    endif
    ; handle The Cause
    if hasCCTheCause
        ; This can be LVLI (CACO-patched) or INGR (unpatched), compilation of cast appears to depend on what script is found by Paprus Compiler
        ccBGSSSE067_HarradaBehaviorScript causeFlora = akTarget as ccBGSSSE067_HarradaBehaviorScript
        if causeFlora
            SetLootableForProducer(baseForm, causeFlora.ccBGSSSE067_IngredientHarrada as Form)
            return
        endif
    endif
    WispCoreScript wispCore = akTarget as WispCoreScript
    if wispCore
        SetLootableForProducer(baseForm, wispCore.glowDust)
        return
    endIf
    ; handle modified apiary if present
    if HearthfireExtendedModIndex != 255
        KmodApiaryScript apiary = akTarget as KmodApiaryScript
        if apiary
            ; there are three items: we choose the critter for loot rule checking, but all items should be looted
            SetLootableForProducer(baseForm, apiary.CritterBeeIngredient)
            return
        endIf
    endIf
    if sirenrootFlower
        ; only the first has contents, the others are never treated as Harvestable
        if akTarget as evgSRharvestsroot || akTarget as EVGSR01HarvestScript || akTarget as evgSR10bosstart
            SetLootableForProducer(baseForm, sirenrootFlower)
            return
        endif
    endif
    if hasOrangeMoon
        ; only the first has contents, the others are never treated as Harvestable
        ORMOrangeActivatorScript orangeTree = akTarget as ORMOrangeActivatorScript
        if orangeTree
            SetLootableForProducer(baseForm, orangeTree.FruitIngredient)
            return
        endif
    endif
    ; test for critters after checking all the synthetic flora
    Critter thisCritter = akTarget as Critter
    if thisCritter
        if thisCritter.nonIngredientLootable
            ; Salmon and other fish - FormList, 0-1 elements seen so far - make a log if > 1
            int lootableCount = thisCritter.nonIngredientLootable.GetSize()
            if lootableCount > 1
                AlwaysTrace(akTarget + " with Base " + baseForm + " has " + lootableCount + "nonIngredientLootable entries")
            elseif lootableCount == 1
                SetLootableForProducer(baseForm, thisCritter.nonIngredientLootable.GetAt(0))
            else
                ; blacklist empty vessel
                ClearLootableForProducer(baseForm)
            endif
        else
            ; everything else - simple ingredient
            SetLootableForProducer(baseForm, thisCritter.lootable)
        endIf
        return
    endIf
    FXfakeCritterScript fakeCritter = akTarget as FXfakeCritterScript
    if fakeCritter
        ; Activation may produce 0-2 items, return the most valuable
        if fakeCritter.myIngredient
            SetLootableForProducer(baseForm, fakeCritter.myIngredient)
        elseif fakeCritter.myFood
            SetLootableForProducer(baseForm, fakeCritter.myFood)
        else
            AlwaysTrace(akTarget + " with Base " + baseForm + " has neither myFood nor myIngredient")
            ClearLootableForProducer(baseForm)
        endif
        return
    endIf
    ClearLootableForProducer(baseForm)
    AlwaysTrace(akTarget + " with Base " + baseForm + " is unsupported scripted ACTI")
endEvent

bool Function IsInHarvestableState(ObjectReference akTarget)
    Form baseForm = akTarget.GetBaseObject()
    ;DebugTrace("IsInHarvestableState: Target " + akTarget + ", Base " + baseForm)
    ; Vanilla ACTI that are categorized as Flora but harvested like critters via scripted ACTI
    NirnrootACTIVATORScript nirnrootACTI = akTarget as NirnrootACTIVATORScript
    if nirnrootACTI
        String nirnrootState = nirnrootACTI.getState()
        return nirnrootState == "WaitingForHarvest"
    endif
    DLC1TrapPoisonBloom poisonBloom = akTarget as DLC1TrapPoisonBloom
    if poisonBloom
        ;DebugTrace("DLC1TrapPoisonBloom State=" + poisonBloom.getState())
        String bloomState = poisonBloom.getState()
        return bloomState != "Done" && bloomState != "Firing" && bloomState != "Disarmed"
    endif
    ; handle Saints and Seducers
    if hasCCSaintsAndSeducers
        ; This can be LVLI (CACO-patched) or INGR (unpatched), compilation of cast appears to depend on what script is found by Paprus Compiler
        ccBGSSSE025_HarvestableActivator saintsFlora = akTarget as ccBGSSSE025_HarvestableActivator
        if saintsFlora
            ;DebugTrace("ccBGSSSE025_HarvestableActivator State=" + saintsFlora.getState())
            return saintsFlora.getState() == "Ready"
        endif
    endif
    ; handle Extended Cut - Saints and Seducers
    if hasExtendedCutSaintsAndSeducers
        EC_HarvestTreeofShades ecssFlora = akTarget as EC_HarvestTreeofShades
        if ecssFlora
            ; deleted once harvested
            return True;
        endif
    endif
    ; handle The Cause
    if hasCCTheCause
        ; This can be LVLI (CACO-patched) or INGR (unpatched), compilation of cast appears to depend on what script is found by Paprus Compiler
        ccBGSSSE067_HarradaBehaviorScript causeFlora = akTarget as ccBGSSSE067_HarradaBehaviorScript
        if causeFlora
            ;DebugTrace("ccBGSSSE067_HarradaBehaviorScript State=" + causeFlora.getState())
            return causeFlora.getState() == "IdleReadyUnharvested"
        endif
    endif
    ; handle vanilla Wisp Core
    if akTarget as WispCoreScript
        return True
    endIf
    ; handle modified apiary if present
    if HearthfireExtendedModIndex != 255 && akTarget as KmodApiaryScript
        ; there are three items: we choose the critter for loot rule checking, but all items should be looted
        return True
    endIf
    if sirenrootFlower
        ; two others are skipped
        if akTarget as evgSRharvestsroot
            return True
        endif
    endif
    if hasOrangeMoon
        if akTarget as ORMOrangeActivatorScript
            return True
        endif
    endif
    AlwaysTrace("IsInHarvestableState not determined for " + akTarget)
    return False
EndFunction

Function DoObjectGlow(ObjectReference akTargetRef, int duration, int reason)
    EffectShader effShader
    if reason >= 0 && reason <= glowReasonSimpleTarget
        effShader = categoryShaders[reason]
    else
        effShader = categoryShaders[glowReasonSimpleTarget]
    endif
    ; no need to check Activation available here
    if effShader && OKToScan() && akTargetRef.Is3DLoaded() && !akTargetRef.IsDisabled()        
        ; play for requested duration - C++ code will tidy up when out of range
        ;DebugTrace("DoObjectGlow for " + akTargetRef.GetDisplayName() + " for " + duration + " seconds")
        effShader.Play(akTargetRef, duration)
    endif
endFunction

; This only handles ore-veins
Event OnObjectGlow(ObjectReference akTargetRef, int duration, int reason)
    ; do not glow ore-vein if it's depleted. Various checks.
    MineOreScript mineable = akTargetRef as MineOreScript
    bool oreHandled = False
    if mineable
        ; Vanilla or CCOR case
        if mineable.ResourceCountCurrent == 0
            ;DebugTrace("Do not glow depleted CCOR/Vanilla ore")
            return
        endif
        oreHandled = True
    elseif CACOModIndex != 255
        ; CACO case
        CACO_MineOreScript cacoMineable = akTargetRef as CACO_MineOreScript
        if cacoMineable
            if cacoMineable.ResourceCountCurrent == 0
                ;DebugTrace("Do not glow depleted CACO ore")
                return
            endif
            oreHandled = True
        endif
    endif
    if hasFossilMining && !oreHandled
        ; Fossil Mining case
        FOS_DigsiteScript digSite = akTargetRef as FOS_DigsiteScript
        if digSite && digsite.GetLinkedRef().IsDisabled()
            ;DebugTrace("Do not glow depleted Fossil digsite")
            return
        endif
        oreHandled = True
    endif
    DoObjectGlow(akTargetRef, duration, reason)
endEvent

Function OnMCMOpen()
    if keyHandlingActive
        AlwaysTrace("MCM opened during keystroke handling")
    endIf
    mcmOpen = True
    SetMCMState(True)
EndFunction

Function OnMCMClose()
    SetMCMState(False)
    mcmOpen = False
EndFunction

; no need to check Activate Controls here, use script Activate or native ActivateRef return code
bool Function OKToScan()
    if mcmOpen
        AlwaysTrace("MCM for SHSE is open")
        return False
    elseif Utility.IsInMenuMode()
        AlwaysTrace("UI has menu open")
        return False
    endIf
    return True
EndFunction

; Periodic poll to check whether native code can be released. If game closes down this will never happen.
; Enter a poll loop if UI State forbids native code from scanning.
Function CheckReportUIState()
    bool goodToGo = OKToScan()
    AlwaysTrace("UI Good-to-go = " + goodToGo + " for request " + pluginNonce + " plugin-delayed = " + pluginDelayed)
    if goodToGo
        ; if UI was detected open, refresh player's equipped/worn items in case they changed
        if pluginDelayed
            ; force plugin refresh of player's current worn and equipped items
            ResetList(list_type_in_use_items)
        endIf
        ReportOKToScan(pluginDelayed, pluginNonce)
        pluginNonce = 0
        pluginDelayed = false
    else
        pluginDelayed = true
        RegisterForSingleUpdate(0.25)
    endIf
EndFunction

; this should not kick off competing OnUpdate cycles
Function StartCheckReportUIState(int nonce)
    AlwaysTrace("Kick off UI State check for request " + nonce + ", plugin nonce = " + pluginNonce)
    if pluginNonce == 0
        pluginNonce = nonce
        pluginDelayed = false
        CheckReportUIState()
    endIf
EndFunction

; OnUpdate is used only while UI is active, until UI State becomes inactive and native code can resume scanning
Event OnUpdate()
    CheckReportUIState()
EndEvent

; Check UI State is OK for scan thread - block the plugin if not, rechecking on a timed poll
Event OnCheckOKToScan(int nonce)
    StartCheckReportUIState(nonce)
EndEvent

; Reset state related to new game/load game
Event OnGameReady()
    ;DebugTrace("SHSE_EventsAlias.OnGameReady")
    ;update CACO and CCOR indices in load order, to handle custom ore mining
    DefaultStrikesBeforeCollection = 1
    CACOModIndex = Game.GetModByName("Complete Alchemy & Cooking Overhaul.esp")
    CCORModIndex = Game.GetModByName("Complete Crafting Overhaul_Remastered.esp")
    if CACOModIndex != 255 || CCORModIndex != 255
        AlwaysTrace("CACO mod index: " + CACOModIndex + ", CCOR mod index: " + CCORModIndex)
        DefaultStrikesBeforeCollection = ((Game.GetFormFromFile(0x01CC0503, "Update.esm") As GlobalVariable).GetValue() As Int)

        ; CCOR has special case for Stalhrim
        if CCORModIndex != 255
            stalhrimOre = Game.GetFormFromFile(0x2B06B, "Dragonborn.esm") As MiscObject
            if stalhrimOre
                AlwaysTrace("Stalhrim Ore resolved OK")
            endif
        endif
    endif

    ;look for Fossil Mining form IDs, to handle fossil handout after mining
    FOS_LItemFossilTierOneGeode = Game.GetFormFromFile(0x3ee7d, "Fossilsyum.esp") as LeveledItem
    if FOS_LItemFossilTierOneGeode
        AlwaysTrace("Fossil Mining found in Load Order")
        hasFossilMining = True
        FOS_LItemFossilTierOneVolcanic = Game.GetFormFromFile(0x3ee7a, "Fossilsyum.esp") as LeveledItem
        FOS_LItemFossilTierOneyum = Game.GetFormFromFile(0x3c77, "Fossilsyum.esp") as LeveledItem
        FOS_LItemFossilTierOneVolcanicDigSite = Game.GetFormFromFile(0x3f41f, "Fossilsyum.esp") as LeveledItem
        FOS_LItemFossilTierTwoVolcanic = Game.GetFormFromFile(0x3ee7b, "Fossilsyum.esp") as LeveledItem
    endif

    ; Check for CC Saints and Seducers
    hasCCSaintsAndSeducers = Game.GetFormFromFile(0x54046, "ccbgssse025-advdsgs.esm") as Activator != None
    AlwaysTrace("CC Saints and Seducers present = " + hasCCSaintsAndSeducers)

    ; Check for Extended Cut - Saints and Seducers
    hasExtendedCutSaintsAndSeducers = Game.GetFormFromFile(0x4800, "Skyrim Extended Cut - Saints and Seducers.esp") as Activator != None
    AlwaysTrace("Extended Cut - Saints and Seducers present = " + hasExtendedCutSaintsAndSeducers)

    ; Check for CC The Cause, testing form injected to Update.esm
    hasCCTheCause = Game.GetFormFromFile(0x3157, "Update.esm") as Activator != None
    AlwaysTrace("CC The Cause present = " + hasCCTheCause)

    ; Check for CC Fishing, the QUST has a property we can use to detect if Fishing is active
    ccFishingDialogue = Game.GetFormFromFile(0x33a55, "ccbgssse001-fish.esm") as ccBGSSSE001_DialogueDetectScript
    AlwaysTrace("CC Fishing present = " + ccFishingDialogue as bool)

    ;update Hearthfire Extended index in load order, to handle Apiary ACTI
    HearthfireExtendedModIndex = Game.GetModByName("hearthfireextended.esp")
    if HearthfireExtendedModIndex != 255
        AlwaysTrace("Hearthfire Extended mod index: " + HearthfireExtendedModIndex)
    endif

    ; Check for Sirenroot - the Misc Object some ACTIs return
    sirenrootFlower = Game.GetFormFromFile(0xb97d9, "evgSIRENROOT.esm") as MiscObject
    AlwaysTrace("Sirenroot present = " + (sirenrootFlower as Bool))

    ; Check for Orange Moon
    hasOrangeMoon = Game.GetFormFromFile(0xe5868, "OrangeMoon.esp") as Activator != None
    AlwaysTrace("Orange Moon present = " + hasOrangeMoon)

    ; yes, this really is the ESP name. And there are three different names.
    MagicChestModIndex = Game.GetModByName("Skyrim_SE_Nexus .esp")
    if MagicChestModIndex == 255
        MagicChestModIndex = Game.GetModByName("Skyrim_SE_Nexus_Chests .esp")
    endif
    if MagicChestModIndex == 255
        MagicChestModIndex = Game.GetModByName("SSENexus OCS Patch.esp")
    endif
    if MagicChestModIndex != 255
        AlwaysTrace("Magic Chest Spell with Multi Linked Containers mod index: " + MagicChestModIndex)
    endif

    ;update Vidani's Bag Of Holding index in load order, to handle Bag as a Transfer List candidate
    VidanisBagOfHoldingModIndex = Game.GetModByName("Vidani's Bag of Holding.esp")
    if VidanisBagOfHoldingModIndex != 255
        AlwaysTrace("Vidani's Bag Of Holding mod index: " + VidanisBagOfHoldingModIndex)
    endif

    ; only need to check Collections requisite data structure on reload, not MCM close
    ResetCollections()
EndEvent
