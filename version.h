#pragma once

constexpr char* SHSE_NAME = "SmartHarvestSE";
constexpr wchar_t* L_SHSE_NAME = L"SmartHarvestSE";
constexpr char* MODNAME = "SmartHarvestSE.esp";

class VersionInfo
{
public:
	static VersionInfo& Instance();
	std::string GetPluginVersionString() const;
	UInt32 GetVersionMajor() const;

private:
	VersionInfo() : m_majorVersion(0) {}
	static VersionInfo* m_instance;
	void GetPluginVersionInfo();
	std::string m_versionString;
	UInt32 m_majorVersion;
};
