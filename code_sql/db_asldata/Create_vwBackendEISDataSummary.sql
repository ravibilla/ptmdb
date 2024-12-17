USE [ASLDATA];
GO

-- Drop the existing view
IF OBJECT_ID('[dbo].vwBackendEISDataSummary', 'V') IS NOT NULL
    DROP VIEW [dbo].vwBackendEISDataSummary;
GO

-- View for Backend EIS Test Summary Data
CREATE VIEW vwBackendEISDataSummary
AS
    SELECT
        T1.Filename AS File_Name, 
		T5.Date AS Test_Date, 
        T5.Time AS Test_Time, 
        T5.Tester, 
		'BE' AS Stage,
        T1.RollID AS Roll, 
		T2.SheetID AS Sheet, 
		T3.QuadID AS Quad, 
		CONCAT(T1.RollID, '-', T2.SheetID) AS Lot_Id, 
		CONCAT(T1.RollID, '-', T2.SheetID, '-', T3.QuadID) AS Quad_Id,
        FORMAT(T4.Xcoord, '00') AS X_Coord, 
		FORMAT(T4.Ycoord, '00') AS Y_Coord, 
		CAST(T4.Binnum AS Int) AS Bin,
        T7.ocv AS OCV_V, 
        T7.conductivity AS Conductivity_uS_cm, 
		T6.EIslope AS EIS_Slope,
        T7.Zreal_1hz * 0.2365 AS Re_Z_1Hz_Ohm_cm2, 
        T7.Zreal_1khz * 0.2365 AS Re_Z_1KHz_Ohm_cm2, 
        T6.Zreal * 0.2365 AS Re_Z_100KHz_Ohm_cm2, 
		T7.Zimag_1hz * 0.2365 AS Im_Z_1Hz_Ohm_cm2, 
        T7.Zimag_1khz * 0.2365 AS Im_Z_1KHz_Ohm_cm2,
        T6.Zimag * 0.2365 AS Im_Z_100KHz_Ohm_cm2,  
        T7.phase_1hz AS Phase_1Hz_Deg, 
        T7.phase_1khz AS Phase_1KHz_Deg, 
        T6.phase AS Phase_100KHz_Deg, 
        T7.phase_min AS Phase_Minimum_Deg
    FROM [ASLDATA].[dbo].[Roll] AS T1
        LEFT OUTER JOIN [ASLDATA].[dbo].[Sheet] AS T2
            ON (T2.RollKey = T1.ID)
        LEFT OUTER JOIN [ASLDATA].[dbo].[Quad] AS T3
            ON (T3.SheetKey = T2.ID)
        LEFT OUTER JOIN [ASLDATA].[dbo].[Die] AS T4
            ON (T4.QuadKey = T3.ID)
        LEFT OUTER JOIN [ASLDATA].[dbo].[batterytester] AS T5
            ON  (T5.Quadkey = T3.ID)
        LEFT OUTER JOIN [ASLDATA].[dbo].[BatteryData] AS T6
            ON (T6.DieKey = T4.ID)
        LEFT OUTER JOIN [ASLDATA].[dbo].[pdata] AS T7
            ON (T7.DieKey = T4.ID)
    WHERE T6.Freq >= 100000
 
-- Test
SELECT * FROM vwBackendEISDataSummary
WHERE Quad_Id LIKE 'C228-1-BL%'



