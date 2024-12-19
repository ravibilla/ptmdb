USE [ASLDATA];
GO

-- Drop the existing view
IF OBJECT_ID('[dbo].vwBackendEISData', 'V') IS NOT NULL
    DROP VIEW [dbo].vwBackendEISData;
GO

-- View for Backend EIS Test Data
CREATE VIEW vwBackendEISData
AS
    SELECT
        T1.Filename AS File_Name, 
		CAST(T5.Date AS Date) AS Test_Date,
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
        CONCAT(FORMAT(T4.Xcoord, '00'), FORMAT(T4.Ycoord, '00')) AS Die_Id,
		CAST(T4.Binnum AS Int) AS Bin,
        T7.ocv AS OCV_V, 
        T7.conductivity AS Conductivity_uS_cm, 
		T6.Freq AS Freq_Hz, 
		T6.Zreal AS Re_Z_Ohm, 
		T6.Zimag AS Im_Z_Ohm, 
		T6.phase AS Phase_Deg, 
		T6.EIslope AS EIS_Slope,
        T7.Freq_1hz AS Freq_1Hz_Hz, 
        T7.Freq_1khz AS Freq_1KHz_Hz,
        T6.Zreal * 0.2365 AS Re_Z_Ohm_cm2, 
        T7.Zreal_1hz * 0.2365 AS Re_Z_1Hz_Ohm_cm2, 
        T7.Zreal_1khz * 0.2365 AS Re_Z_1KHz_Ohm_cm2, 
        T6.Zimag * 0.2365 AS Im_Z_Ohm_cm2, 
		T7.Zimag_1hz * 0.2365 AS Im_Z_1Hz_Ohm_cm2, 
        T7.Zimag_1khz * 0.2365 AS Im_Z_1KHz_Ohm_cm2, 
        T7.phase_1hz AS Phase_1Hz_Deg, 
        T7.phase_1khz AS Phase_1KHz_Deg, 
        T7.phase_min AS Phase_Minimum_Deg,
        T7.Freq_min AS Freq_At_Phase_Min_Hz,
        T7.Zreal_min AS Re_Z_At_Phase_Min_Ohm_cm2
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
 
-- Test
SELECT * FROM vwBackendEISData
WHERE Roll LIKE 'C228' AND Freq_Hz like '1.%'
