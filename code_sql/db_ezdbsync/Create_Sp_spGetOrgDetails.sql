Use [EZ_DB_Sync];
Go

--Stored procedure to get Organization details
Create Procedure spGetOrgDetails
@OrgId Nvarchar(16)
As
Begin
    If (@OrgId IS NULL)
    Begin
        Select OrgID From vwOrgDetails
        Order By OrgID Asc
    End

    Else
    Begin
        Select * From vwOrgDetails
        Where OrgID LIKE @OrgId 
    End
End


--Test
Execute spGetOrgDetails 'GB-%'
Execute spGetOrgDetails NULL

