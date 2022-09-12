-- About WorldCatLocalSearch.lua
--
-- WorldCatLocalSearch.lua does a WorldCatLocal search.  It provides buttons to do searches based on title, isxn or oclc number.
-- It can also do an automatic search using a search priority string, in which case it will use the first field listed in the string that has a value.
-- The valid fields are title, isxn and oclc.
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.

local settings = {};
settings.AutoSearch = GetSetting("AutoSearch");

local interfaceMngr = nil;
local worldCatLocalForm = {};
worldCatLocalForm.Form = nil;
worldCatLocalForm.Browser = nil;
worldCatLocalForm.RibbonPage = nil;

require "Atlas.AtlasHelpers";

function Init()
	interfaceMngr = GetInterfaceManager();
	
	-- Create a form
	worldCatLocalForm.Form = interfaceMngr:CreateForm("WorldCat Local Search", "Script");

	-- Add a browser
	worldCatLocalForm.Browser = worldCatLocalForm.Form:CreateBrowser("WorldCat Local Search", "WorldCat Local Search Browser", "WorldCat Local Search", "Chromium");

	-- Hide the text label
	worldCatLocalForm.Browser.TextVisible = false;	

	-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
	worldCatLocalForm.RibbonPage = worldCatLocalForm.Form:GetRibbonPage("WorldCat Local Search");

	-- Create the search buttons
	local button = nil;
	button = worldCatLocalForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", "WorldCat Local");
	if (CanSearchTitle() ~= true) then
		button.BarButton.Enabled = false;
	end
	
	button = worldCatLocalForm.RibbonPage:CreateButton("Search ISXN", GetClientImage("Search32"), "SearchISXN", "WorldCat Local");
	if (CanSearchISXN() ~= true) then
		button.BarButton.Enabled = false;
	end
	
	button = worldCatLocalForm.RibbonPage:CreateButton("Search OCLC", GetClientImage("Search32"), "SearchOCLC", "WorldCat Local");
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
	local value = GetFieldValue("Transaction", "ESPNumber")
	if (value ~= nil and value ~= "") then
		return true;
	end
	
	return false;
end

function CanSearchISXN()
	local value = GetFieldValue("Transaction", "ISSN")
	if (value ~= nil and value ~= "") then
		return true;
	end
	
	return false;
end

function GetTitle()
	local title;
	if	(GetFieldValue("Transaction", "RequestType") == "Article") then
		title = GetFieldValue("Transaction", "PhotoArticleTitle");
	else
		title = GetFieldValue("Transaction", "LoanTitle");
	end
	
	if (title == nil) then
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
	
	worldCatLocalForm.Browser:Navigate(GetSetting("WorldCatURL"));
end

function SearchTitle()
	Search("ti:"..GetTitle());
end

function SearchISXN()
	local value = GetFieldValue("Transaction", "ISSN");
	
	if (value == nil) then
		value = "";
	end
	
	local prefix;
	
	if (GetFieldValue("Transaction", "RequestType") == "Article") then
		prefix = "n2:";
	else
		prefix ="bn:";
	end
	
	Search(prefix..value);
end

function SearchOCLC()
	local value = GetFieldValue("Transaction", "ESPNumber");
	
	if	(value == nil) then
		value = "";
	end
	
	Search("no:"..value);
end

function Search(searchTerm)
	worldCatLocalForm.Browser:Navigate(GetSetting("WorldCatURL").."/search?scope=0&oldscope=&wcsbtn2w=Search&q="..AtlasHelpers.UrlEncode(searchTerm));
end


	



