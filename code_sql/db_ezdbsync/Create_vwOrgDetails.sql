Use [EZ_DB_Sync];
Go

--View for Organization Details
Create View vwOrgDetails
As
    Select sJob As OrgID, sORbActive As IsOrgActive, vCD.CategoryName As OrgCategory, 
        sORProjectName As OrgProjectName, sORCode As OrgCode, sORName As OrgName, 
        sORNotes As OrgNotes, vBD.sBGDescr As OrgAddress, sORbManufacture As IsOrgManufacturer, 
        sORbSupplier  As IsOrgSupplier, sORbCustomer As IsOrgCustomer,
        CAST(DATEADD(HOUR, -7, DATEADD(MILLISECOND, Convert(Bigint, Substring(PT.DateTimeCreated, 1, 13)) % 1000, DATEADD(SECOND, Convert(Bigint, Substring(PT.DateTimeCreated, 1, 13)) / 1000, '19700101'))) As Datetime) As DateTimeCreated,
        PT.Initiator
    From 
        (Select iObjID, sN, sV 
        From  [EZ_Fusion].[dbo].[tbl_OR_EZ_Obj_Data]
        ) As SourceTable
    PIVOT
        (
        Max(sV)
        For sN IN (sORCode, sORbActive, CurrentStatus, Initiator, DateTimeCreated, sORbManufacture, sORbSupplier,sORbCustomer, sORName, sORProjectName, sORCG, sORBGFirst, sORBG_Last_Home_BG, sORNotes)
        ) As PT
    LEFT JOIN [EZ_Fusion].[dbo].[tbl_OR_EZ_Obj]
    On  [EZ_Fusion].[dbo].[tbl_OR_EZ_Obj].iObjID = PT.iObjID 
    LEFT JOIN vwCategoryDetails vCD
    On vCD.CategoryID = PT.sORCG
    LEFT JOIN vwBlogDetails vBD
    On vBD.sBG = PT.sORBG_Last_Home_BG
 

--Test
Select * From vwOrgDetails
Order By OrgName
