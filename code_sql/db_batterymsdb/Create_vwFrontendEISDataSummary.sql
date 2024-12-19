USE batterymsdb;

-- Drop the existing view
DROP VIEW IF EXISTS vwFrontendEISDataSummary;

-- Create a view for Frontend EIS Test Data
CREATE VIEW vwFrontendEISDataSummary
AS
    SELECT  
        NULL AS File_Name,
        DATE(T3.quad_start_time) AS Test_Date,
        TIME(T3.quad_start_time) AS Test_Time,
        T5.tester AS Tester,
        'FE' AS Stage,
        T1.roll_id AS Roll, 
        T2.sheet_id AS Sheet, 
        T3.quad_id AS Quad,
        CONCAT(T1.roll_id, '-', T2.sheet_id) AS Lot_Id,
        CONCAT(T1.roll_id, '-', T2.sheet_id, '-', T3.quad_id) AS Quad_Id,
        LPAD(T4.col - 1, 2, '0') AS X_Coord,
        LPAD(T4.row - 1, 2, '0') AS Y_Coord,
        CAST(T4.bin_category AS Int) AS Bin,
        T7.ocv AS OCV_V,
        T7.conductivity AS Conductivity_uS_cm,
        NULL AS EIS_Slope,
        NULL AS Freq_1Hz_Hz, 
        NULL AS Freq_1KHz_Hz,
        T7.zreal_1hz * 0.2365 AS Re_Z_1Hz_Ohm_cm2, 
        T7.zreal_1khz * 0.2365 AS Re_Z_1KHz_Ohm_cm2, 
        T6.zreal * 0.2365 AS Re_Z_100KHz_Ohm_cm2, 
        T7.zimag_1hz * -0.2365 AS Im_Z_1Hz_Ohm_cm2, 
        T7.zimag_1khz * -0.2365 AS Im_Z_1KHz_Ohm_cm2,
        T6.zimag * -0.2365 AS Im_Z_100KHz_Ohm_cm2,
        T7.zphase_1hz AS Phase_1Hz_Deg, 
        ATAN(T7.zimag_1khz / T7.zreal_1khz) * (180 / PI()) AS  Phase_1KHz_Deg, 
        T6.phase AS Phase_100KHz_Deg, 
        T7.phase_min AS Phase_Minimum_Deg,
        T7.freq_min AS Freq_At_Phase_Min_Hz,
        T7.zreal_min * 0.2365 AS Re_Z_At_Phase_Min_Ohm_cm2
    FROM batterymsdb.Roll AS T1
        LEFT OUTER JOIN sheet T2 
            ON (T2.roll_key = T1.key)  
        LEFT OUTER JOIN quad T3 
            ON (T3.sheet_key = T2.key)  
        LEFT OUTER JOIN uut T4 
            ON (T4.quad_key = T3.key)  
        LEFT OUTER JOIN batterytester T5 
            ON (T4.key = T5.uut_key)  
        LEFT OUTER JOIN batterydata T6 
            ON (T6.uut_key = T4.key)  
        LEFT OUTER JOIN pdata T7 
            ON (T7.uut_key = T4.key)
    WHERE T6.freq >= 100000
 
-- Test
SELECT * FROM vwFrontendEISDataSummary
WHERE Roll LIKE 'C228'
