DataMapping = {};
DataMapping.Icons = {};
DataMapping.SourceTables = {};
DataMapping.SourceFields = {};

DataMapping.Icons["TitleSearch"] = { Ares = "Search32", ILLiad = "Search32" };
DataMapping.Icons["IsxnSearch"] = { Ares = "Search32", ILLiad = "Search32" };
DataMapping.Icons["OclcNumberSearch"] = { Ares = "Search32", ILLiad = "Search32" };

DataMapping.SourceTables["Ares"] = "Item";
DataMapping.SourceTables["ILLiad"] = "Transaction";

DataMapping.SourceFields["MonographOrLoanTitle"] = { Ares = "Title", ILLiad = "LoanTitle" };
DataMapping.SourceFields["SerialOrArticleTitle"] = { Ares = "Title", ILLiad = "PhotoJournalTitle" };
DataMapping.SourceFields["Isxn"] = { Ares = "ISXN", ILLiad = "ISSN" };
DataMapping.SourceFields["OclcNumber"] = { Ares = "ESPNumber", ILLiad = "ESPNumber" };