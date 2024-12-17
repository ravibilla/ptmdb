USE batterymsdb;

-- Drop the existing procedure
DROP PROCEDURE IF EXISTS spGetFrontendEISDataSummaryByDate;

DELIMITER //

-- Create a procedure to get all Frontend EIS Test Summary Data by Date
CREATE PROCEDURE spGetFrontendEISDataSummaryByDate(
    IN p_StartDate DATE, 
    IN p_EndDate DATE
)
BEGIN
    -- Declare error handling variables
    DECLARE error_code INT DEFAULT 0;
    DECLARE error_message VARCHAR(512);
    DECLARE error_sqlstate VARCHAR(5);

    -- Declare exception handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Capture error details
        GET DIAGNOSTICS CONDITION 1
            error_code = MYSQL_ERRNO,
            error_message = MESSAGE_TEXT,
            error_sqlstate = RETURNED_SQLSTATE;

        -- Rollback transaction if active
        ROLLBACK;

        -- Return error details to the client
        SELECT 
            'ERROR' AS status,
            error_code AS ErrorNumber,
            error_message AS ErrorMessage,
            error_sqlstate AS ErrorState;
    END;

    -- Start transaction
    START TRANSACTION;

    -- Main query
    SELECT * FROM vwFrontendEISDataSummary
    WHERE Test_Date >= p_StartDate
        AND Test_Date <= p_EndDate
    ORDER BY Lot_Id DESC;

    -- Commit transaction
    COMMIT;
END //

DELIMITER ;

-- Test
CALL  spGetFrontendEISDataSummaryByDate ('2024-12-01', '2024-12-03');