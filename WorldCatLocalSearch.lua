-- About WorldCatLocalSearch.lua
--
-- WorldCatLocalSearch.lua does a WorldCatLocal search.  It provides buttons to do searches based on title, isxn or oclc number.
-- It can also do an automatic search using a search priority string, in which case it will use the first field listed in the string that has a value.
-- The valid fields are title, isxn and oclc.
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.

local settings = {};
settings.AutoSearch = GetSetting("AutoSearch");
settings.WorldcatURL = GetSetting("WorldCatURL");
settings.SearchPriority = GetSetting("SearchPriority");

local interfaceMngr = nil;
local worldCatLocalForm = {};
worldCatLocalForm.Form = nil;
worldCatLocalForm.Browser = nil;
worldCatLocalForm.RibbonPage = nil;

luanet.load_assembly("System.Windows.Forms");
luanet.load_assembly("log4net");

local productName = luanet.import_type("System.Windows.Forms.Application").ProductName;
local log = luanet.import_type("log4net.LogManager").GetLogger("AtlasSystems.Addons.WorldCatLocalSearch");

require "Atlas.AtlasHelpers";

function Init()
	interfaceMngr = GetInterfaceManager();

	-- Create a form
	worldCatLocalForm.Form = interfaceMngr:CreateForm("WorldCat Local Search", "Script");

	-- Add a browser
	local browserType;
	if AddonInfo.Browsers and AddonInfo.Browsers.WebView2 and AddonInfo.Browsers.WebView2 then
		browserType = "WebView2";
	else
		browserType = "Chromium";
	end
	worldCatLocalForm.Browser = worldCatLocalForm.Form:CreateBrowser("WorldCat Local Search",
		"WorldCat Local Search Browser", "WorldCat Local Search", browserType);

	-- Hide the text label
	worldCatLocalForm.Browser.TextVisible = false;

	-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
	worldCatLocalForm.RibbonPage = worldCatLocalForm.Form:GetRibbonPage("WorldCat Local Search");

	-- Create the search buttons
	local button = nil;
	button = worldCatLocalForm.RibbonPage:CreateButton("Search Title",
		GetClientImage(DataMapping.Icons.TitleSearch[productName]), "SearchTitle", "WorldCat Local");
	if (CanSearchTitle() ~= true) then
		button.BarButton.Enabled = false;
	end

	button = worldCatLocalForm.RibbonPage:CreateButton("Search ISXN",
		GetClientImage(DataMapping.Icons.IsxnSearch[productName]), "SearchISXN", "WorldCat Local");
	if (CanSearchISXN() ~= true) then
		button.BarButton.Enabled = false;
	end

	button = worldCatLocalForm.RibbonPage:CreateButton("Search OCLC",
		GetClientImage(DataMapping.Icons.OclcNumberSearch[productName]), "SearchOCLC", "WorldCat Local");
	if (CanSearchOCLC() ~= true) then
		button.BarButton.Enabled = false;
	end

	-- After we add all of our buttons and form elements, we can show the form.
	worldCatLocalForm.Form:Show();

	if settings.AutoSearch then
		AutoSearch();
	end
end

function CanSearchTitle()
	return GetTitle() ~= "";
end

function CanSearchOCLC()
	local value = GetFieldValue(DataMapping.SourceTables[productName], DataMapping.SourceFields.OclcNumber[productName]);
	if value ~= nil and value ~= "" then
		return true;
	end

	return false;
end

function CanSearchISXN()
	local value = GetFieldValue(DataMapping.SourceTables[productName], DataMapping.SourceFields.Isxn[productName]);
	if value ~= nil and value ~= "" and GetIsxnType(value) ~= "invalid" then
		return true;
	end

	return false;
end

function GetTitle()
	local title;

	if productName == "Ares" then
		if GetFieldValue("Item", "ItemType") == "Serial" then
			title = GetFieldValue("Item", DataMapping.SourceFields.SerialOrArticleTitle[productName]);
		else
			title = GetFieldValue("Item", DataMapping.SourceFields.MonographOrLoanTitle[productName]);
		end
	elseif productName == "ILLiad" then
		if GetFieldValue("Transaction", "RequestType") == "Article" then
			title = GetFieldValue("Transaction", DataMapping.SourceFields.SerialOrArticleTitle[productName]);
		else
			title = GetFieldValue("Transaction", DataMapping.SourceFields.MonographOrLoanTitle[productName]);
		end
	end

	if title == nil then
		title = "";
	end

	return title;
end

function AutoSearch()
	local priorities = AtlasHelpers.StringSplit(",", GetSetting("SearchPriority"));

	for index, priority in ipairs(priorities) do
		local priorityLower = priority:lower();

		if (priorityLower == "title" and CanSearchTitle()) then
			SearchTitle();
			return;
		elseif (priorityLower == "oclc" and CanSearchOCLC()) then
			SearchOCLC();
			return;
		elseif (priorityLower == "isxn" and CanSearchISXN()) then
			SearchISXN();
			return;
		end
	end

	worldCatLocalForm.Browser:Navigate(settings.WorldcatURL);
end

function SearchTitle()
	Search("ti:" .. GetTitle());
end

function SearchISXN()
	local value = GetFieldValue(DataMapping.SourceTables[productName], DataMapping.SourceFields.Isxn[productName]);
	local isxnType = GetIsxnType(value);
	local prefix;

	if isxnType == "isbn" then
		prefix = "bn:";
	elseif isxnType == "issn" then
		prefix = "n2:";
	else
		interfaceMngr:ShowMessage("ISxN '" .. tostring(value) .. "' is invalid. Search will not be performed.", "Invalid ISxN");
		log:Warn("ISxN '" .. tostring(value) .. "' is invalid. Search will not be performed.");
		return;
	end

	Search(prefix .. value);
end

function GetIsxnType(isxn)
	local cleanIsxn = isxn:match("%w+"):gsub("%-", "");

	if cleanIsxn:find("^%d%d%d%d%d%d%d%w$") then
		return "issn";
	elseif cleanIsxn:find("^%d%d%d%d%d%d%d%d%d%w$") or cleanIsxn:find("^%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
		return "isbn";
	else
		return "invalid";
	end
end

function SearchOCLC()
	local value = GetFieldValue(DataMapping.SourceTables[productName], DataMapping.SourceFields.OclcNumber[productName]);

	if value == nil then
		value = "";
	end

	Search("no:" .. value);
end

function Search(searchTerm)
	worldCatLocalForm.Browser:Navigate(settings.WorldcatURL ..
	"/search?scope=0&oldscope=&wcsbtn2w=Search&q=" .. AtlasHelpers.UrlEncode(searchTerm));
end
