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

local importButton = nil;
local pageWatcherEnabled = false;
local pageWatcherTimer = nil;

luanet.load_assembly("System");
luanet.load_assembly("System.Windows.Forms");
luanet.load_assembly("log4net");

local types = {};
types["System.Timers.Timer"] = luanet.import_type("System.Timers.Timer");

local productName = luanet.import_type("System.Windows.Forms.Application").ProductName;
local sourceTable = nil;
local log = luanet.import_type("log4net.LogManager").GetLogger("AtlasSystems.Addons.WorldCatLocalSearch");

local browserType;
if AddonInfo.Browsers and AddonInfo.Browsers.WebView2 and AddonInfo.Browsers.WebView2 then
	browserType = "WebView2";
else
	browserType = "Chromium";
end

require "AtlasHelpers";

function Init()
	interfaceMngr = GetInterfaceManager();

	if productName == "ILLiad" then
		sourceTable = "Transaction";
		productName = productName .. GetFieldValue("Transaction", "RequestType");
	elseif productName == "Ares" then
		sourceTable = "Item";
	else
		log:ErrorFormat("This addon is not supported for {0}. Halting addon execution.", productName);
		return;
	end

	-- Create a form
	worldCatLocalForm.Form = interfaceMngr:CreateForm("WorldCat Local Search", "Script");

	-- Add a browser
	worldCatLocalForm.Browser = worldCatLocalForm.Form:CreateBrowser("WorldCat Local Search",
		"WorldCat Local Search Browser", "WorldCat Local Search", browserType);

	-- Hide the text label
	worldCatLocalForm.Browser.TextVisible = false;

	-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
	worldCatLocalForm.RibbonPage = worldCatLocalForm.Form:GetRibbonPage("WorldCat Local Search");

	-- Create the search buttons
	local button = nil;
	button = worldCatLocalForm.RibbonPage:CreateButton("Search Title",
		GetClientImage(DataMapping.Icons.TitleSearch[productName]), "SearchTitle", "Search Options");
	if (CanSearchTitle() ~= true) then
		button.BarButton.Enabled = false;
	end

	button = worldCatLocalForm.RibbonPage:CreateButton("Search ISXN",
		GetClientImage(DataMapping.Icons.IsxnSearch[productName]), "SearchISXN", "Search Options");
	if (CanSearchISXN() ~= true) then
		button.BarButton.Enabled = false;
	end

	button = worldCatLocalForm.RibbonPage:CreateButton("Search OCLC",
		GetClientImage(DataMapping.Icons.OclcNumberSearch[productName]), "SearchOCLC", "Search Options");
	if (CanSearchOCLC() ~= true) then
		button.BarButton.Enabled = false;
	end
	
	importButton = worldCatLocalForm.RibbonPage:CreateButton("Import", 
		GetClientImage(DataMapping.Icons.Import[productName]), "BibImport", "Import");
	importButton.BarButton.Enabled = false;

	-- After we add all of our buttons and form elements, we can show the form.
	worldCatLocalForm.Form:Show();

	OnFormClosing:RegisterFormClosingEvent(interfaceMngr, StopPageWatcherTimer);

	if settings.AutoSearch then
		AutoSearch();
	end
end

function StartPageWatcherTimer()
    if not pageWatcherEnabled then
        log:Debug("Starting record page watcher.");

		pageWatcherTimer = types["System.Timers.Timer"](3000);
		pageWatcherTimer:add_Elapsed(IsRecordPage);
		pageWatcherTimer:Start();

        pageWatcherEnabled = true;
    end
end

function StopPageWatcherTimer()
    if pageWatcherEnabled then
        log:Debug("Stopping record page watcher.");
        pageWatcherTimer:Stop();
		pageWatcherTimer:Dispose();

        pageWatcherEnabled = false;
    end
end

function CanSearchTitle()
	local value = GetFieldValue(sourceTable, DataMapping.SourceFields.Title[productName]);

	if value and value ~= "" then
		return true;
	end

	return false;
end

function CanSearchOCLC()
	local value = GetFieldValue(sourceTable, DataMapping.SourceFields.OclcNumber[productName]);
	if value and value ~= "" then
		return true;
	end

	return false;
end

function CanSearchISXN()
	local value = GetFieldValue(sourceTable, DataMapping.SourceFields.Isxn[productName]);
	if value and value ~= "" and GetIsxnType(value) ~= "invalid" then
		return true;
	end

	return false;
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
	Search("ti:" .. GetFieldValue(sourceTable, DataMapping.SourceFields.Title[productName]));
end

function SearchISXN()
	local value = GetFieldValue(sourceTable, DataMapping.SourceFields.Isxn[productName]);
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
	local value = GetFieldValue(sourceTable, DataMapping.SourceFields.OclcNumber[productName]);

	if not value then
		value = "";
	end

	Search("no:" .. value);
end

function Search(searchTerm)
	worldCatLocalForm.Browser:Navigate(settings.WorldcatURL ..
	"/search?scope=0&oldscope=&wcsbtn2w=Search&q=" .. AtlasHelpers.UrlEncode(searchTerm));

	StartPageWatcherTimer();
end

function IsRecordPage()
	if worldCatLocalForm.Form and worldCatLocalForm.Browser then
		local oclcNumber = (worldCatLocalForm.Browser.Address):match("title/(%d+)");

		if not oclcNumber then
			log:Debug("Not a record page.");
			importButton.BarButton.Enabled = false;
			return;
		end

		local recordPageLoadedScript = [[(function(oclcNumber){
			if (document.getElementById("oclcnumber-" + oclcNumber) != null){
				return "True";
			}
			return "False";
		})]];

		local recordPageLoaded = worldCatLocalForm.Browser:EvaluateScript(recordPageLoadedScript, {oclcNumber}).Result == "True";

		if recordPageLoaded then
			log:Debug("Record page found.");
			importButton.BarButton.Enabled = true;
		else
			log:Debug("Not a record page.");
			importButton.BarButton.Enabled = false;
		end
	end
end

function BibImport()
	local oclcNumber = (worldCatLocalForm.Browser.Address):match("title/(%d+)");
	
	log:DebugFormat("Importing bib info for OCLC# {0}", oclcNumber);

	local getImportValuesScript = [[(function(oclcNumber){
		var title = "";
		var titleText = document.getElementsByTagName("title")[0].innerText;
		title = titleText.match(/[^|]+/);
		
		var author = "";
		var aCollection = document.getElementsByTagName("a");
		for (let a of aCollection){
			if (a.getAttribute("data-testid") == "author-" + oclcNumber + "-0"){
				author = a.innerText;
			}
		}
		
		var isxn = "";
		var spanCollection = document.getElementsByTagName("span");
		for (let span of spanCollection){
			var isxnPattern = new RegExp("is.n\-" + oclcNumber)
			if (isxnPattern.test(span.getAttribute("aria-labelledby"))){
				isxn = (span.innerText).match(/[x\d-]+/i)[0];
			}
		}
		
		var publisherInfo = "";
		for (let span of spanCollection){
			if (span.getAttribute("data-testid") == "publisher-" + oclcNumber){
				publisherInfo = span.innerText;
			}
		}
		
		return title + "||" + author + "||" + isxn + "||" + publisherInfo;
	})]];

	local importValues = worldCatLocalForm.Browser:EvaluateScript(getImportValuesScript, {oclcNumber}).Result;

	local title, author, isxn, publisherInfo = importValues:match("(.+)||(.+)||(.+)||(.+)");
	local publisher = Trim(publisherInfo:match("(.+),"));
	local publicationPlace = Trim(publisherInfo:match(",(.+),"));
	local publicationDate = Trim(publisherInfo:match("%d+%w+$"));

	SetValueIfNotNil(title, "Title");
	SetValueIfNotNil(author, "Author");
	SetValueIfNotNil(isxn, "Isxn");
	SetValueIfNotNil(publisher, "Publisher");
	SetValueIfNotNil(publicationPlace, "PublicationPlace");
	SetValueIfNotNil(publicationDate, "PublicationDate");
	SetValueIfNotNil(oclcNumber, "OclcNumber");

	if productName:find("ILLiad") then
		ExecuteCommand("SwitchTab", "Detail");
	elseif productName == "Ares" then
		ExecuteCommand("SwitchTab", {"Details"});
	end
end

function SetValueIfNotNil(value, field)
	if value then
		SetFieldValue(sourceTable, DataMapping.ImportFields[field][productName], value);
	end
end

function Trim(str)
	if not str then
		return nil;
	else
		return str:match("^%s*(.-)%s*$");
	end
end