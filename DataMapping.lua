DataMapping = {};
DataMapping.Icons = {};
DataMapping.SourceFields = {};
DataMapping.ImportFields = {};

DataMapping.Icons["TitleSearch"] = { Ares = "Search32", ILLiadLoan = "Search32", ILLiadArticle = "Search32" };
DataMapping.Icons["IsxnSearch"] = { Ares = "Search32", ILLiadLoan = "Search32", ILLiadArticle = "Search32" };
DataMapping.Icons["OclcNumberSearch"] = { Ares = "Search32", ILLiadLoan = "Search32", ILLiadArticle = "Search32" };
DataMapping.Icons["Import"] = { Ares = "Import32", ILLiadLoan = "Import32", ILLiadArticle = "Import32" };

DataMapping.SourceFields["Title"] = { Ares = "Title", ILLiadLoan = "LoanTitle", ILLiadArticle = "PhotoJournalTitle" };
DataMapping.SourceFields["Isxn"] = { Ares = "ISXN", ILLiadLoan = "ISSN", ILLiadArticle = "ISSN" };
DataMapping.SourceFields["OclcNumber"] = { Ares = "ESPNumber", ILLiadLoan = "ESPNumber", ILLiadArticle = "ESPNumber" };

DataMapping.ImportFields["Title"] = { Ares = "Title", ILLiadLoan = "LoanTitle", ILLiadArticle = "PhotoJournalTitle" };
DataMapping.ImportFields["Isxn"] = { Ares = "ISXN", ILLiadLoan = "ISSN", ILLiadArticle = "ISSN"};
DataMapping.ImportFields["Author"] = { Ares = "Author", ILLiadLoan = "LoanAuthor", ILLiadArticle = "ItemAuthor" };
DataMapping.ImportFields["Publisher"] = { Ares = "Publisher", ILLiadLoan = "LoanPublisher", ILLiadArticle = "PhotoItemPublisher" };
DataMapping.ImportFields["PublicationPlace"] = { Ares = "PubPlace", ILLiadLoan = "LoanPlace", ILLiadArticle = "PhotoItemPlace" };
DataMapping.ImportFields["PublicationDate"] = { Ares = "PubDate", ILLiadLoan = "LoanDate", ILLiadArticle = "PhotoJournalYear" };
DataMapping.ImportFields["OclcNumber"] = { Ares = "ESPNumber", ILLiadLoan = "ESPNumber", ILLiadArticle = "ESPNumber" };