USE [ASLDATA];
GO

-- Drop the existing procedure
IF OBJECT_ID('[dbo].spGetBackendEISDataByDate', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].spGetBackendEISDataByDate;
GO

-- Stored procedure to get Backend EIS Test Data at all frequencies by Date
CREATE PROCEDURE spGetBackendEISDataByDate
@StartDate Date, @EndDate Date
AS
BEGIN
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED
        BEGIN TRANSACTION
            SELECT * FROM vwBackendEISData
            WHERE Test_Date >= @StartDate
                AND Test_Date <= @EndDate
            ORDER BY Lot_Id DESC
        Commit TRANSACTION    
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        --Show error details in SSMS
        SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage, 
            ERROR_PROCEDURE() AS ErrorProcedure, ERROR_STATE() AS ErrorState, 
            ERROR_SEVERITY() AS ErrorSeverity, ERROR_LINE() AS ErrorLine

       --Return error details to client calling the stored procedure
        DECLARE @ErrorMessage Nvarchar(512), @ErrorSeverity Int, @ErrorState Int
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), 
            @ErrorState = ERROR_STATE()
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    End CATCH
End

-- Test
EXECUTE  spGetBackendEISDataByDate '2024-12-01', '2024-12-06'

